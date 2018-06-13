class TOR
  COOKIE_PATH = '/Users/twer/Library/Application Support/TorBrowser-Data/Tor/control_auth_cookie'
  @redis = Redis.new(
    host: Rails.configuration.redis['host'],
    port: Rails.configuration.redis['port'],
    db: Rails.configuration.redis['database']['tor'],
  )

  class NoAvailableInstance < Exception; end

  class << self
    def redis
      @redis
    end

    def concurrence_uuid(instance)
      instance.nil? ? 'TorNewnymJob' : "TorNewnymJob_#{instance}"
    end

    def password_key(instance)
      "#{instance}_pass"
    end

    def extract_instance(uuid)
      match = uuid.match(/^TorNewnymJob_(\d+)$/)
      match && match[1].to_i
    end

    def log(instance, message)
      File.open("tmp/tor/#{instance}/access.log", 'a') do |file|
        file.write("(#{instance})[#{Time.now.strftime('%H:%M:%S')}] #{message}\n")
      end
    end

    def new_nym(instance)
      raise "Instance #{instance} is not running" unless instances.include?(instance)
      password = redis.get password_key(instance)
      system("expect -f ./lib/tor-newnym.exp #{instance + 1} #{password}")
      JobConcurrence.where(uuid: concurrence_uuid(instance)).destroy_all
      release_instance(instance)
    end

    def hash_password(password)
      (`tor --hash-password #{password}`).chop
    end

    def instances
      pid_files = Dir.glob('tmp/pids/*')
      matches = pid_files.map { |file| file.match(/tor\.(?<pid>\d+)\.pid$/) }
      pids = matches.compact.map { |match| match[:pid] }
      pids.map(&:to_i)
    end

    def require_instance
      redis.rpop(:instance_pool).tap do |instance|
        if instance.nil?
          sleep 10.seconds
          raise NoAvailableInstance
        end
        log(instance, 'instance required')
      end
    end

    def release_instance(instance)
      redis.lpush(:instance_pool, instance)
      log(instance, 'instance released')
    end

    def reset_instance_pool
      redis.del(:instance_pool)
      instances.each do |instance|
        redis.lpush(:instance_pool, instance)
        File.write("tmp/tor/#{instance}/access.log", nil)
      end
    end

    def new_instance
      latest_instance = instances.max || 9000
      ports = { socks: latest_instance + 10, control: latest_instance + 11, dns: latest_instance + 12 }
      data_dir = "tmp/tor/#{ports[:socks]}"
      Dir.mkdir('tmp/tor') unless Dir.exists?('tmp/tor')
      Dir.mkdir(data_dir) unless Dir.exists?(data_dir)
      password = SecureRandom.base58
      result = `tor --defaults-torrc @CONFDIR@/torrc-defaults --RunAsDaemon 1 --DataDirectory #{data_dir} --PidFile #{Dir.pwd}/tmp/pids/tor.#{ports[:socks]}.pid --SocksPort #{ports[:socks]} --ControlPort #{ports[:control]} --DnsPort #{ports[:dns]} --HashedControlPassword #{hash_password(password)}`
      error = result.match(/\[err\](.*)/)
      raise error[0] unless error.nil?
      redis.set(password_key(ports[:socks]), password)
      redis.lpush(:instance_pool, ports[:socks])
    end

    def kill_instance(port)
      system("pkill -F ./tmp/pids/tor.#{port}.pid")
    end

    def kill_all
      instances.each(&TOR.method(:kill_instance))
    end

    def request(option, instance = nil)
      instance ||= require_instance
      log(instance, 'request started')
      option[:proxy] = "socks5://localhost:#{instance}/"
      RestClient::Request.execute(option).tap do
        log(instance, '!!!request finished')
        release_instance(instance)
      end
    rescue RestClient::TooManyRequests, RestClient::Forbidden => e
      JobConcurrence.tor_newnym(instance)
      log(instance, 'wait for new nym')
      raise e
    rescue Exception => e
      release_instance(instance) unless instance.nil?
      raise e
    end
  end
end
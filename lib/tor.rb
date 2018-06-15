class TOR
  COOKIE_PATH = '/Users/twer/Library/Application Support/TorBrowser-Data/Tor/control_auth_cookie'
  @redis = Redis.new(
    host: Rails.configuration.redis['host'],
    port: Rails.configuration.redis['port'],
    db: Rails.configuration.redis['database']['tor'],
  )

  class NoAvailableInstance < Exception; end
  class InstanceNotAvailable < Exception; end

  class << self
    def redis
      @redis
    end

    def concurrence_uuid(port)
      port.nil? ? 'TorNewnymJob' : "TorNewnymJob_#{port}"
    end

    def password_key(port)
      "#{port}_pass"
    end

    def new_nym_key(port)
      "#{port}_newnym"
    end

    def extract_instance(uuid)
      match = uuid.match(/^TorNewnymJob_(\d+)$/)
      match && match[1].to_i
    end

    def log(instance, message, level = :info)
      name, _ = instance.split('#')
      File.open("tmp/tor/#{name}/access.log", 'a') do |file|
        file.write("(#{instance})[#{Time.now.strftime('%H:%M:%S')} #{level}] #{message}\n")
      end
    end

    def new_nym(port)
      raise InstanceNotAvailable.new("Tor server on port #{port} is not running") unless instances.include?(port)
      password = redis.get password_key(port)
      system("expect -f ./lib/tor-newnym.exp #{port + 1} #{password}")
      loop do
        instance = redis.rpoplpush(new_nym_key(port), :instance_pool)
        break if instance.nil?
        log(instance, 'instance released')
      end
      JobConcurrence.where(uuid: concurrence_uuid(port)).destroy_all
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
      instance = redis.brpop(:instance_pool, 10)
      raise NoAvailableInstance if instance.nil?
      instance[1].tap do |ins|
        port, _ = ins.split('#')
        raise InstanceNotAvailable.new("Tor server on port #{port} is not running") unless instances.include?(port.to_i)
        if JobConcurrence.where(uuid: concurrence_uuid(port)).exists?
          redis.lpush("#{port}_newnym", ins)
          log(ins, 'wait for new nym', :warning)
          raise InstanceNotAvailable.new("Tor server on port #{port} is newing nym")
        end
        log(ins, 'instance required')
      end
    end

    def release_instance(instance)
      port, _ = instance.split('#')
      return unless instances.include?(port.to_i)
      redis.lpush(:instance_pool, instance)
      log(instance, 'instance released')
    end

    def reset_instance_pool
      redis.del(:instance_pool)
      instances.each do |instance|
        redis.del("#{instance}_newnym")
        redis.lpush(:instance_pool, 3.times.map { |n| "#{instance}##{n + 1}" })
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
      redis.lpush(:instance_pool, 3.times.map { |n| "#{ports[:socks]}##{n + 1}" })
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
      port, _ = instance.split('#')
      option[:proxy] = "socks5://localhost:#{port}/"
      RestClient::Request.execute(option).tap do
        log(instance, '!!!request finished')
        release_instance(instance)
      end
    rescue RestClient::TooManyRequests, RestClient::Forbidden => e
      redis.lpush("#{port}_newnym", instance)
      JobConcurrence.tor_newnym(port)
      log(instance, 'wait for new nym', :warning)
      raise e
    rescue Exception => e
      release_instance(instance) unless instance.nil?
      raise e
    end
  end
end
class TOR
  INSTANCE_CONCURRENCE = 3
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

    def newnym_key(port)
      "#{port}_newnym"
    end

    def extract_instance(uuid)
      match = uuid.match(/^TorNewnymJob_(\d+)$/)
      match && match[1].to_i
    end

    def log(instance, message, level = :info)
      return if level == :info
      name, _ = instance.to_s.split('#')
      File.open(Rails.root.join("tmp/tor/#{name}/access.log"), 'a') do |file|
        file.write("(#{instance})[#{Time.now.strftime('%H:%M:%S')} #{level}] #{message}\n")
      end
    end

    def new_nym(port, reset_pool = true)
      raise InstanceNotAvailable.new("Tor server on port #{port} is not running") unless instances.include?(port.to_i)

      version = redis.incr newnym_key(port)
      log(port, "new nym version is #{version}", :info)
      return false if version > 1
      log(port, 'start new nym', :info)
      password = redis.get password_key(port)
      system("expect -f #{Rails.root.join('lib/tor-newnym.exp')} #{port.to_i + 1} #{password}")
      redis.del newnym_key(port)
      pool_push(INSTANCE_CONCURRENCE.times.map { |n| "#{port}##{n + 1}" }) if reset_pool
      log(port, 'new nym finished', :warning)
    rescue Exception => e
      log(port, "new nym error #{e.message}", :error)
      raise e
    end

    def retry_new_nym(port, option)
      return nil unless new_nym(port, false)
      RestClient::Request.execute(option).tap do
        log(instance, 'retry new nym succeed', :success)
        pool_push(INSTANCE_CONCURRENCE.times.map { |n| "#{port}##{n + 1}" })
      end
    rescue RestClient::TooManyRequests, RestClient::Forbidden
      log(instance, 'retry new nym failed', :warning)
      retry_new_nym(port, option)
    end

    def hash_password(password)
      (`tor --hash-password #{password}`).chop
    end

    def instances
      Dir.chdir(Rails.root())
      pid_files = Dir.glob('tmp/pids/*')
      matches = pid_files.map { |file| file.match(/tor\.(?<pid>\d+)\.pid$/) }
      pids = matches.compact.map { |match| match[:pid] }
      pids.map(&:to_i)
    end

    def pool_pop
      redis.spop(:instance_pool).tap do |instance|
        if instance.nil?
          sleep 3
          raise NoAvailableInstance
        end
      end
    end

    def pool_push(instances)
      instances = Array(instances)
      redis.sadd(:instance_pool, instances)
    end

    def pool_size
      redis.scard(:instance_pool)
    end

    def pool_instances
      redis.smembers(:instance_pool)
    end

    def require_instance
      pool_pop.tap do |instance|
        port, _ = instance.split('#')
        raise InstanceNotAvailable.new("Tor server on port #{port} is not running") unless instances.include?(port.to_i)
        if redis.exists(newnym_key(port))
          log(instance, 'wait for new nym', :warning)
          raise InstanceNotAvailable.new("Tor server on port #{port} is newing nym")
        end
        log(instance, 'instance required')
      end
    end

    def release_instance(instance)
      port, _ = instance.split('#')
      return unless instances.include?(port.to_i)
      pool_push(instance)
      log(instance, 'instance released')
    end

    def reset_instance_pool
      redis.del(:instance_pool)
      instances.each do |instance|
        redis.del(newnym_key(instance))
        pool_push(INSTANCE_CONCURRENCE.times.map { |n| "#{instance}##{n + 1}" })
        File.write("tmp/tor/#{instance}/access.log", nil)
      end
    end

    def new_instance(latest_port = nil)
      latest_port ||= instances.max || 19000
      ports = { socks: latest_port + 10, control: latest_port + 11, dns: latest_port + 12 }
      data_dir = "tmp/tor/#{ports[:socks]}"
      Dir.mkdir('tmp/tor') unless Dir.exists?('tmp/tor')
      Dir.mkdir(data_dir) unless Dir.exists?(data_dir)
      password = SecureRandom.base58
      result = `tor --defaults-torrc @CONFDIR@/torrc-defaults --RunAsDaemon 1 --DataDirectory #{data_dir} --PidFile #{Dir.pwd}/tmp/pids/tor.#{ports[:socks]}.pid --SocksPort #{ports[:socks]} --ControlPort #{ports[:control]} --DnsPort #{ports[:dns]} --HashedControlPassword #{hash_password(password)}`
      error = result.match(/\[err\](.*)/)
      raise error[0] unless error.nil?
      redis.set(password_key(ports[:socks]), password)
      pool_push(INSTANCE_CONCURRENCE.times.map { |n| "#{ports[:socks]}##{n + 1}" })
    end

    def new_instances(number)
      number.times { new_instance }
    end

    def kill_instance(port = nil)
      port ||= instances.max
      File.write("tmp/tor/#{port}/access.log", nil)
      system("pkill -F ./tmp/pids/tor.#{port}.pid")
    end

    def kill_all
      instances.each(&TOR.method(:kill_instance))
    end

    def request(option, instance = nil)
      instance ||= require_instance
      start_time = Time.now
      log(instance, 'started')
      port, _ = instance.split('#')
      option[:proxy] = "socks5://localhost:#{port}/"
      option[:timeout] = 30
      RestClient::Request.execute(option).tap do
        cost_time = (Time.now - start_time).round(1)
        log(instance, "finished in #{cost_time}s", :success)
        release_instance(instance)
      end
    rescue RestClient::TooManyRequests, RestClient::Forbidden => e
      cost_time = (Time.now - start_time).round(1)
      log(instance, "failed in #{cost_time}s, new nym", :error)
      puts e
      DelegateJob.perform_later('TOR', 'new_nym', port)
      # new_nym(port)
      # raise e
      request(option)
    rescue Exception => e
      release_instance(instance) unless instance.nil?
      puts e
      # raise e
      request(option)
    end
  end
end
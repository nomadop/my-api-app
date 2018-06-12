class TOR
  COOKIE_PATH = '/Users/twer/Library/Application Support/TorBrowser-Data/Tor/control_auth_cookie'
  @redis = Redis.new(
    host: Rails.configuration.redis['host'],
    port: Rails.configuration.redis['port'],
    db: Rails.configuration.redis['database']['tor'],
  )

  class << self
    def redis
      @redis
    end

    def new_nym(instance)
      raise "Instance #{instance} is not running" unless instances.include?(instance)
      password = redis.get "#{instance}_pass"
      system("expect -f ./lib/tor-newnym.exp #{instance + 1} #{password}")
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

    def connections
      keys = instances.map { |ins| "#{ins}_conn" }
      conns = redis.mget(*keys).map(&:to_i)
      Hash[instances.zip(conns)]
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
      redis.set "#{ports[:socks]}_pass", password
    end

    def kill_instance(port)
      system("pkill -F ./tmp/pids/tor.#{port}.pid")
    end

    def kill_all
      instances.each(&TOR.method(:kill_instance))
    end
  end
end
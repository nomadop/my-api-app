class Utility
  class << self
    def match_json_var(identity, code)
      regex = %r(var #{identity}\s*=\s*(.*);)
      match = regex.match(code)
      JSON.parse(match[1])
    end

    def vat(price, rate)
      [(price * rate).floor, 1].max
    end

    def include_vat(price)
      price + vat(price, 0.1) + vat(price, 0.05)
    end

    def exclude_val(price)
      return nil if price.nil? || price < 1
      (1..price).bsearch { |p| include_vat(p) >= price }
    end

    def unescapeHTML(string)
      Nokogiri::HTML.fragment(string).text
    end

    def timeout(duration)
      start = Time.now
      yield
      while Time.now - start < duration
        sleep(0.1)
      end
    end

    def tor_newnym
      binary = File.read('/Users/twer/Library/Application Support/TorBrowser-Data/Tor/control_auth_cookie')
      hex = binary.unpack('H*').first
      system("expect -f /Users/twer/tor-newnym.exp #{hex}")
    end

    def parse_cookies(cookie_array, domain = 'http://store.steampowered.com')
      uri = URI(domain)
      parse_cookie = Proc.new { |c| HTTP::Cookie.parse(c, uri) }
      cookie_array.flat_map(&parse_cookie)
    end

    def parse_jar(cookies, old_jar = HTTP::CookieJar.new)
      cookies.reduce(old_jar) do |jar, cookie|
        cookie.value === 'deleted' ? jar.delete(cookie) : jar.add(cookie)
        jar
      end
    end

    def remove_cookies(cookies, jar)
      cookies.each(&jar.method(:delete))
    end

    def format_currency(price)
      ActionController::Base.helpers.number_to_currency(price / 100.0, locale: :cn)
    end
  end
end
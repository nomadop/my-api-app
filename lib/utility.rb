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
  end
end
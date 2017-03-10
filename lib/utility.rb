class Utility
  class << self
    def match_json_var(identity, code)
      regex = %r(var #{identity} = (.*);)
      match = regex.match(code)
      JSON.parse(match[1])
    end

    def exclude_val(price)
      price - (price * 0.1).floor - (price * 0.05).floor
    end

    def unescapeHTML(string)
      Nokogiri::HTML.fragment(string).text
    end
  end
end
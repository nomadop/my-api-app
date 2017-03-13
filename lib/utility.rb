class Utility
  class << self
    def match_json_var(identity, code)
      regex = %r(var #{identity} = (.*);)
      match = regex.match(code)
      JSON.parse(match[1])
    end

    def exclude_val(price)
      (1..price).bsearch { |p| p + (p * 0.1).floor + (p * 0.05).floor >= price }
    end

    def unescapeHTML(string)
      Nokogiri::HTML.fragment(string).text
    end
  end
end
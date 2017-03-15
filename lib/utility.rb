class Utility
  class << self
    def match_json_var(identity, code)
      regex = %r(var #{identity} = (.*);)
      match = regex.match(code)
      JSON.parse(match[1])
    end

    def vat(price, rate)
      [(price * rate).floor, 1].max
    end

    def exclude_val(price)
      (1..price).bsearch { |p| p + vat(p, 0.1) + vat(p, 0.05) >= price }
    end

    def unescapeHTML(string)
      Nokogiri::HTML.fragment(string).text
    end
  end
end
class Utility
  class << self
    def match_json_var(identity, code)
      regex = %r(var #{identity} = (.*);)
      match = regex.match(code)
      JSON.parse(match[1])
    end
  end
end
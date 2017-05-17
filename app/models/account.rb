class Account < ApplicationRecord
  def cookie_jar
    uri = URI('http://store.steampowered.com')
    parse_cookie = Proc.new {|c| HTTP::Cookie.parse(c, uri)}
    cookie.split(';').flat_map(&parse_cookie).reduce(HTTP::CookieJar.new, &:add)
  end

  def get_cookie(name)
    cookie = cookie_jar.find { |cookie| cookie.name == name.to_s }
    cookie.value
  end

  def set_cookie(name, value)
    jar = cookie_jar.tap do |jar|
      cookie = jar.parse("#{name}=#{value}", URI('http://store.steampowered.com'))[0]
      jar.add(cookie)
    end
    update(cookie: jar.cookies.join(';'))
  end

  def remove_cookie(name)
    uri = URI('http://store.steampowered.com')
    parse_cookie = Proc.new {|c| HTTP::Cookie.parse(c, uri)}
    jar = cookie.split(';').flat_map(&parse_cookie).reduce(HTTP::CookieJar.new) do |jar, cookie|
      jar.add(cookie) unless cookie.name == name
      jar
    end
    update(cookie: jar.cookies.join(';'))
  end

  def session_id
    get_cookie(:sessionid)
  end

  def session_id=(session_id)
    set_cookie(:sessionid, session_id)
  end

  def update_cookie(response)
    jar = response.cookie_jar.cookies.reduce(cookie_jar) do |jar, cookie|
      cookie = jar.parse(cookie.to_s, URI('http://store.steampowered.com'))[0]
      jar.add(cookie) unless cookie.name == 'steamRememberLoginError'
      jar
    end
    update(cookie: jar.cookies.join(';'))
  end

  def refresh
    response = Authentication.check_login(cookie)
    update_cookie(response)
  end
end

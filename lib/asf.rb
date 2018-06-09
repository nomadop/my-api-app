class ASF
  class << self
    def send_command(command)
      url = "http://127.0.0.1:1242/Api/Command/#{URI.encode(command)}"
      option = {
        method: :post,
        url: url,
        headers: {
          Authentication: ',WrBiVaRd93[7m^E'
        },
      }
      response = RestClient::Request.execute(option)
      JSON.parse(response.body).tap(&method(:puts))
    end
  end
end
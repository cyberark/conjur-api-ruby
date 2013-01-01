module Conjur
  class Valueset < RestClient::Resource
    include Exists
    include HasAttributes
    
    def create
      self.post
    end
    
    def upload_url
      self['/upload_url'].url
    end
    
    def upload(name, value, mime_type)
      size = value.length
      upload_io = UploadIO.new(StringIO.new(value), mime_type, name)
      uuid = nil
      begin
        require 'uri'
        url = URI.parse(upload_url)
        req = Net::HTTP::Post::Multipart.new url.request_uri, "file" => upload_io, "size" => size
        server = Net::HTTP.new(url.host, url.port)
        server.use_ssl = true if url.scheme == "https"
        res = server.start do |http|
          http.request(req)
        end
        code = res.code.to_i
        unless [ 200, 201 ].member?(code)
          raise RestClient::Exceptions::EXCEPTIONS_MAP[code].new(nil, code)
        end
        response = MultiJson.decode(res.body)
        uuid = response.values[0]
      ensure
        file.close
      end

      self['/values'].post name: name, uuid: uuid, size: size
    end
    
    def value identifier
      Value.new self["values/#{escape identifier}"].url, credentials
    end
  end
end

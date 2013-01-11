
module Conjur
  class API
    class << self
      def data_access_service_url(account, path = nil, params = {})
        provider = 'inscitiv'
        base_url = if path.nil? || path.empty?
          "#{Conjur::DAS::API.host}/data/#{account}/#{provider}"
        else
          path = path.split('/').collect do |p|
            # Best possible answer I could find
            # http://stackoverflow.com/questions/2834034/how-do-i-raw-url-encode-decode-in-javascript-and-ruby-to-get-the-same-values-in
            URI.escape(p, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
          end.join('/')
          "#{Conjur::DAS::API.host}/data/#{account}/#{provider}/#{path}"
        end
        if params.nil? || params.empty?
          base_url
        else
          query_string = params.map do |name,values|
            values = [ values ] unless values.is_a?(Array)
            values.map do |value|
              name = URI.escape(name, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
              value = URI.escape(value || "", Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
              "#{name}=#{value}"
            end
          end.flatten.join("&")
          "#{base_url}?#{query_string}"
        end
      end
    end
  end
end

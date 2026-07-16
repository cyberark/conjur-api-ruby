require 'json'
require 'conjur/api/router'

module Conjur
  class API
    #@!group Server version

    # Retrieve the Conjur server version.
    #
    # Queries the '/info' endpoint (available on Conjur Enterprise), falling back to
    # the root endpoint (available on Conjur OSS, and as a legacy fallback on
    # Enterprise) if '/info' is unavailable or its response can't be parsed. The
    # result is memoized on this instance.
    #
    # @return [String] the server version, e.g. "1.21.1.1-25".
    # @raise [Conjur::FeatureNotAvailable] if the version can't be determined from
    #   either endpoint.
    def server_version
      return @server_version if @server_version

      @server_version = version_from_info || version_from_root ||
        raise(Conjur::FeatureNotAvailable, "Unable to determine Conjur server version")
    end

    #@!endgroup

    private

    def version_from_info
      body = JSON.parse(Router.server_info.get.body)
      body.dig('services', 'possum', 'version')
    rescue RestClient::Exception, JSON::ParserError
      nil
    end

    def version_from_root
      response = Router.server_root.get
      content_type = response.headers[:content_type].to_s

      if content_type.include?('application/json')
        JSON.parse(response.body)['version']
      else
        match = response.body.match(%r{<d[dt]>\s*Version\s*(?:</d[dt]>\s*<dd>\s*)?([^\s<]+)\s*</dd>})
        match && match[1]
      end
    rescue RestClient::Exception, JSON::ParserError
      nil
    end
  end
end

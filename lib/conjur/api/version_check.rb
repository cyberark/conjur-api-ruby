module Conjur
  class API
    #@!group Server version

    # Verify that the Conjur server version is at least `min_version`.
    #
    # Conjur versions carry a build suffix after a hyphen (e.g. "1.21.1.1-25")
    # which is not part of the comparable version, so it's stripped before comparing.
    #
    # @param min_version [String] the minimum required version, e.g. "1.21.1".
    # @return [true] if the server version is sufficient.
    # @raise [Conjur::FeatureNotAvailable] if the server version is unparseable or
    #   lower than `min_version`.
    def verify_min_server_version!(min_version)
      detected = server_version.split('-').first

      begin
        detected_version = Gem::Version.new(detected)
        required_version = Gem::Version.new(min_version)
      rescue ArgumentError
        raise Conjur::FeatureNotAvailable, "Unable to parse Conjur server version #{server_version.inspect}"
      end

      if detected_version < required_version
        raise Conjur::FeatureNotAvailable,
          "Conjur server version #{server_version} is less than the minimum required version #{min_version}"
      end

      true
    end

    #@!endgroup
  end
end

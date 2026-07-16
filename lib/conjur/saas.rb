require 'uri'

module Conjur
  # Detects whether a Conjur appliance URL points at CyberArk Secrets Manager, SaaS.
  # SaaS appliances do not expose the '/info' or root version endpoints used to
  # determine server version, so features that depend on those endpoints must be
  # rejected outright for SaaS rather than attempting a version check.
  module Saas
    # Hostname suffixes used by CyberArk Secrets Manager, SaaS appliances.
    SUFFIXES = %w[
      .cyberark.cloud
      .integration-cyberark.cloud
      .test-cyberark.cloud
      .dev-cyberark.cloud
      .cyberark-everest-integdev.cloud
      .cyberark-everest-pre-prod.cloud
      .sandbox-cyberark.cloud
      .pt-cyberark.cloud
    ].freeze

    HOSTNAME_PATTERN = /(\.secretsmgr|-secretsmanager)(#{SUFFIXES.map { |s| Regexp.escape(s) }.join('|')})\z/.freeze

    # Returns true if `url` is a CyberArk Secrets Manager, SaaS appliance URL.
    #
    # @param url [String, nil] the appliance URL to check.
    # @return [Boolean]
    def self.appliance_url?(url)
      return false unless url

      uri = URI.parse(url)
      return false unless uri.scheme == 'https'
      return false unless uri.host

      !!(uri.host.downcase =~ HOSTNAME_PATTERN)
    rescue URI::InvalidURIError, ArgumentError
      false
    end
  end
end

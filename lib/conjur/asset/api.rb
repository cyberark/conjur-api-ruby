module Conjur
  module Asset
    class API < Conjur::API
      class << self
        def host
          ENV['CONJUR_ASSET_SERVICE_URL'] || Conjur::Core::API.host
        end
      end
    end
  end
end

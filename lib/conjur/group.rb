module Conjur
  class Group < RestClient::Resource
    include ActsAsAsset
    include ActsAsRole
  end
end

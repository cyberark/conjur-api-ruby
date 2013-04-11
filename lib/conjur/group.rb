module Conjur
  class Group < RestClient::Resource
    include ActsAsResource
    include ActsAsRole
    include HasId
    include HasAttributes
  end
end

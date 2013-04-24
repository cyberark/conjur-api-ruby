module Conjur
  module ActsAsAsset
    def self.included(base)
      base.instance_eval do
        include HasId
        include Exists
        include HasOwner
        include ActsAsResource
        include HasAttributes
      end
    end
  end
end
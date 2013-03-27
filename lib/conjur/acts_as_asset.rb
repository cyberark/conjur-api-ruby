module Conjur
  module ActsAsAsset
    def self.included(base)
      base.instance_eval do
        include ActsAsResource
        include HasAttributes
        include Exists
        include HasId
      end
    end
  end
end
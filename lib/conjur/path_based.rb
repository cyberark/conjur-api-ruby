module Conjur
  module PathBased
    def account
      match_path(0..0)
    end

    def kind
      match_path(2..2)
    end
    
    protected
    
    def match_path(range)
      require 'uri'
      tokens = URI.parse(self.url).path[1..-1].split('/')[range]
      tokens.map{|t| URI.unescape(t)}.join('/')
    end
  end
end
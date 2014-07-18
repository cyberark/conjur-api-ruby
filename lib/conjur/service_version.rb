module Conjur
  class ServiceVersion
    class << self
      def greater_than_or_equal_to(version, major, minor)
        actual_major, actual_minor = version.split('.')
        return actual_major.to_i >= major && actual_minor.to_i >= minor
      end
    end
  end
end

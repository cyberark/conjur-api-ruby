module Conjur
  module LogSource
    def log(&block)
      if Conjur.log
        Conjur.log << "["
        Conjur.log << username
        Conjur.log << "] "
        yield Conjur.log
        Conjur.log << "\n"
      end
    end
  end
end
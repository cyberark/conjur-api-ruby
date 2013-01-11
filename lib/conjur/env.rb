module Conjur
  extend self

  def service_base_port
    (ENV['CONJUR_SERVICE_BASE_PORT'] || 5000 ).to_i
  end
  
  def customer
    ENV['CONJUR_CUSTOMER'] or raise "No CONJUR_CUSTOMER defined"
  end
  
  def env
    ENV['CONJUR_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "development"
  end
  
  def stack
    case env
    when "development", "stage"
      "dev"
    else
      ENV['CONJUR_STACK'] || "echo"
    end
  end
end
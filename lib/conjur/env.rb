module Conjur
  extend self

  def service_base_port
    (ENV['CONJUR_SERVICE_BASE_PORT'] || 5000 ).to_i
  end
  
  def account
    ENV['CONJUR_ACCOUNT'] or raise "No CONJUR_ACCOUNT defined"
  end
  
  def env
    ENV['CONJUR_ENV'] || ENV['RAILS_ENV'] || ENV['RACK_ENV'] || "development"
  end
  
  def stack
    ENV['CONJUR_STACK'] || case env
    when "production"
      "v2"
    else
      env
    end
  end
end
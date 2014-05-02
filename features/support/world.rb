require 'timeout'
require 'active_support'

module ApiWorld
  attr_reader :role, :resource
  def create_role
    @role = api.create_role "test-role:#{namespace}/role"
  end

  def create_resource
    @resource = api.create_resource "test-resource:#{namespace}/resource"
  end

  def check_permission
    @role.permitted? @resource, 'eat'
  end

  def start_follower &done
    @queue = Queue.new
    Thread.new do
      begin
        Timeout::timeout(15) do
          catch(:done) do
            api.audit follow: true do |event|
              throw(:done) if done[event]
            end
          end
          @queue << :succeed
        end
      rescue Timeout::ExitException
        @queue << :fail
      end
    end
  end

  def await_follower
    @queue.pop.should == :succeed
  end

  def namespace
    @namespace ||= api.create_variable('text/plain', 'unique-id').id
  end

  def api
    @api ||= create_api
  end

  def create_api
    require 'conjur/api'
    Conjur::API.new_from_key 'admin', admin_password
  end

  def admin_password
    unless ENV['CONJUR_ADMIN_PASSWORD']
      file = ENV['CONJUR_ADMIN_PASSWORD_FILE'] or raise "missing $CONJUR_ADMIN_PASSWORD and $CONJUR_ADMIN_PASSWORD_FILE"
      raise "File '#{file}' not found for $CONJUR_ADMIN_PASSWORD_FILE" unless File.file?(file)
      ENV['CONJUR_ADMIN_PASSWORD'] = File.read(file).strip
    end
    ENV['CONJUR_ADMIN_PASSWORD']
  end
end

World(ApiWorld)
require 'sidekiq/version'
require 'sidekiq/client'
require 'sidekiq/worker'
require 'sidekiq/rails' if defined?(::Rails)
require 'sidekiq/redis_connection'

require 'sidekiq/extensions/action_mailer' if defined?(::ActionMailer)
require 'sidekiq/extensions/active_record' if defined?(::ActiveRecord)

module Sidekiq

  DEFAULTS = {
    :queues => [],
    :concurrency => 25,
    :require => '.',
    :environment => nil,
  }

  def self.options
    @options ||= DEFAULTS.dup
  end

  def self.options=(opts)
    @options = opts
  end

  ##
  # Configuration for Sidekiq server, use like:
  #
  #   Sidekiq.configure_server do |config|
  #     config.redis = Sidekiq::RedisConnection.create(:namespace => 'myapp', :size => 25, :url => 'redis://myhost:8877/mydb')
  #     config.server_middleware do |chain|
  #       chain.add MyServerHook
  #     end
  #   end
  def self.configure_server
    yield self if server?
  end

  ##
  # Configuration for Sidekiq client, use like:
  #
  #   Sidekiq.configure_client do |config|
  #     config.redis = Sidekiq::RedisConnection.create(:namespace => 'myapp', :size => 1, :url => 'redis://myhost:8877/mydb')
  #   end
  def self.configure_client
    yield self unless server?
  end

  def self.server?
    defined?(Sidekiq::CLI)
  end

  def self.redis
    @redis ||= Sidekiq::RedisConnection.create
  end

  def self.redis=(hash)
    if !hash.is_a?(Hash)
      puts "*****************************************************
Sidekiq.redis now takes a Hash:
old: Sidekiq.redis = Sidekiq::RedisConnection.create(:url => 'redis://foo.com', :namespace => 'abc', :size => 12)
new: Sidekiq.redis = { :url => 'redis://foo.com', :namespace => 'xyz', :size => 12 }
Called from #{caller[0]}
*****************************************************"
      @redis = hash
    else
      @redis = RedisConnection.create(hash)
    end
  end

  def self.client_middleware
    @client_chain ||= Client.default_middleware
    yield @client_chain if block_given?
    @client_chain
  end

  def self.server_middleware
    @server_chain ||= Processor.default_middleware
    yield @server_chain if block_given?
    @server_chain
  end

end

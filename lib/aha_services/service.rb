class Service
  include Networking
  include Errors
  include Schema
  extend Schema::ClassMethods
  
  # Public: Gets the configuration data for this Service instance.
  #
  # Returns a Hash.
  attr_reader :data
  
  # Public: Gets the unique payload data for this Service instance.
  #
  # Returns a Hash.
  attr_reader :payload

  # Public: Gets the identifier for the Service's event.
  #
  # Returns a Symbol.
  attr_reader :event

  # Sets the Faraday::Connection for this Service instance.
  #
  # http - New Faraday::Connection instance.
  #
  # Returns a Faraday::Connection.
  attr_writer :http
  
  def initialize(event = :push, data = {}, payload = nil)
    @event = event.to_sym
    @data = data || {}
    @payload = payload #|| sample_payload
    @event_method = ["receive_#{event}", "receive_event"].detect do |method|
      respond_to?(method)
    end
  end
  
  def self.default_http_options
    @@default_http_options ||= {
      :request => {:timeout => 10, :open_timeout => 5},
      :ssl => {:verify_depth => 5},
      :headers => {}
    }
  end
  

end
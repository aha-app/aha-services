class Service
  include Networking
  include Errors
  include Schema
  include Api
  extend Schema::ClassMethods
  
  # Public: Aha! API client for calling back into Aha!.
  #
  # Returns an AhaApi::Client.
  attr_reader :api
  
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
  
  attr_reader :event_method
  
  # Sets the Faraday::Connection for this Service instance.
  #
  # http - New Faraday::Connection instance.
  #
  # Returns a Faraday::Connection.
  attr_writer :http
  
  def initialize(event, data = {}, payload = nil)
    @event = event.to_sym
    @data = data || {}
    @payload = Hashie::Mash.new(payload)
    @event_method = ["receive_#{event}", "receive_event"].detect do |method|
      respond_to?(method)
    end
    @api = allocate_api_client
  end
  
  def self.default_http_options
    @@default_http_options ||= {
      :request => {:timeout => 10, :open_timeout => 5},
      :ssl => {:verify_depth => 5},
      :headers => {}
    }
  end
  
  def respond_to_event?
    !@event_method.nil?
  end
  
  def receive(timeout = nil)
    return unless respond_to_event?
    timeout_sec = (timeout || 20).to_i
    Timeout.timeout(timeout_sec, TimeoutError) do
      send(event_method)
    end

    self
  rescue Service::ConfigurationError, Errno::EHOSTUNREACH, Errno::ECONNRESET, SocketError, Net::ProtocolError => err
    if !err.is_a?(Service::Error)
      err = ConfigurationError.new(err)
    end
    raise err
  end
end
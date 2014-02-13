class GenericResource

  include Networking
  include Errors

  attr_reader :logger

  def initialize(service)
    @service = service
    @logger = service.data.logger || allocate_logger
  end

  def parse(body)
    if body.nil? or body.length < 2
      {}
    else
      JSON.parse(body)
    end
  end

  def prepare_request
    http.headers['Content-Type'] = 'application/json'
  end

  def self.default_http_options
    @@default_http_options ||= {
      :request => {:timeout => 310, :open_timeout => 5},
      :ssl => {:verify => false, :verify_depth => 5},
      :headers => {}
    }
  end

  def allocate_logger
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger
  end
end

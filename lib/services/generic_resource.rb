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

  def hashie_or_array_of_hashies(response_body)
    parsed_response_body = parse(response_body)
    if parsed_response_body.is_a? Array
      parsed_response_body.collect { |element| Hashie::Mash.new(element) }
    else
      Hashie::Mash.new(parsed_response_body)
    end
  end

  def found_resource(response)
    hashie_or_array_of_hashies(response.body) if response.status == 200
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

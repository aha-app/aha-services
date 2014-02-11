class RedmineResource
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
    http.headers['X-Redmine-API-Key'] = @service.data.api_key
  end

  def process_response(response, *success_codes, &block)
    if success_codes.include?(response.status)
      yield Hashie::Mash.new parse(response.body)
    elsif response.status.between?(400, 499)
      error = parse(response.body)
      raise RemoteError, "Error message: #{error['message']}"
    else
      raise RemoteError, "Unhandled error: STATUS=#{response.status} BODY=#{response.body}"
    end
  end

  def self.default_http_options
    @@default_http_options ||= {
      :request => {:timeout => 310, :open_timeout => 5},
      :ssl => {:verify => false, :verify_depth => 5},
      :headers => {}
    }
  end

  def allocate_logger
    @logger = AhaLogger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger
  end

  def create_integrations reference, **fields
    fields.each do |field, value|
      @service.api.create_integration_field(reference, @service.class.service_name, field, value)
    end
  end
end

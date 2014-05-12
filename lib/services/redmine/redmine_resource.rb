class RedmineResource
  include Networking
  include Errors

  attr_reader :logger

  def initialize(service)
    @service = service
    @payload = @service.payload
    @logger = service.data.logger || allocate_logger
  end

  def parse(body)
    return (body.nil? or body.length < 2) ? {} : JSON.parse(body)
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
      raise RemoteError, "Error message: #{(error['errors'] || []).join(', ')}"
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

  def create_integrations resource, reference, fields
    fields.each do |field, value|
      @service.api.create_integration_fields(resource, reference, @service.class.service_name, fields)
    end
  end

  def get_integration_field integration_fields, field_name
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.service_name == @service.class.service_name and f.name == field_name
    end
    field && field.value
  end
end

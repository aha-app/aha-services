require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
#require 'sinatra/reloader'
require 'optparse'

require File.expand_path("../../aha-services.rb", __FILE__)

#
# App that responds to requests from remote Aha! instance.
#
class ProxyApp < Sinatra::Base
  enable :logging
  #register Sinatra::Reloader
  
  #
  # Configure the server.
  #
  get '/configuration' do 
    configuration = {
      services: AhaService.service_classes.collect do |service| 
      
        {
          service_name: service.service_name,
          title: service.title,
          schema: service.schema.collect do |field|
            # Replace any Proc options.
            o = field[2].dup
            o.each { |k, v| o[k] = "remote_collection" if k.to_s == "collection" }
            
            {
              type: field[0],
              name: field[1],
              options: o
            }
          end
        }
      end
    }
    
    content_type :json
    JSON.pretty_generate(configuration)
  end
  post '/send_event' do
    request_payload = Hashie::Mash.new(JSON.parse(request.body.read))
    
    result = {messages: []}
    
    service_class = AhaService.service_classes.detect {|s| s.service_name == request_payload.service_name }
    
    logger.info("Got data: #{request_payload.inspect}")
    
    data = request_payload.user_data
    data['logger'] = ArrayLogger.new(result[:messages])
    data['api_client'] = AhaApi::Client.new(
      :domain => data.account_domain,
      :url_base => data.api_url_base,
      :oauth_token => data.api_token,
      :logger => data['logger'])

    logger.info("Set data: #{data.inspect}")
    
    service = service_class.new(data, request_payload.payload, request_payload.meta_data)
    begin
      service.receive(request_payload.event)
      result[:meta_data] = service.meta_data.to_hash
    rescue Exception => e    
      result[:exception] = {exception_class: e.class.to_s, message: e.message, backtrace: e.backtrace}
    end
    
    logger.info("RESULT: #{result.inspect}")
    
    content_type :json
    JSON.pretty_generate(result)
  end
  post '/remote_collection' do
    request_payload = Hashie::Mash.new(JSON.parse(request.body.read))
    
    service_class = AhaService.service_classes.detect {|s| s.service_name == request_payload.service_name }
    field = service_class.field_by_name(request_payload.field_name)
    result = field[2][:collection].call(request_payload.meta_data, request_payload.user_data)
    
    content_type :json
    JSON.pretty_generate(result)
  end
  
  
  # Logger to capture service log messages into an array.
  class ArrayLogger < Logger
    def initialize(array)
      super(nil)
      @array = array
    end

    def add(severity, message = nil, progname = nil, &block)
      return true if severity < @level

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
        end
      end
      
      # We force encode the string in UTF-8 so it can pass through JSON.
      message.encode!("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "?")
      
      @array << {severity: severity, message: message}

      true
    end
  end
  
  run!
end


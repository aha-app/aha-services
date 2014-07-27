require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/reloader'
require 'optparse'

require File.expand_path("../../aha-services.rb", __FILE__)

#
# App that responds to requests from remote Aha! instance.
#
class ProxyApp < Sinatra::Base
  register Sinatra::Reloader
  
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
            {
              type: field[0],
              name: field[1],
              options: field[2]
            }
          end
        }
      end
    }
    
    content_type :json
    JSON.pretty_generate(configuration)
  end
  post '/send_event' do
    result = {}
    
    
    result[:messages] = ["Hello world"]
  
    content_type :json
    JSON.pretty_generate(result)
  end
  
  run!
end

require 'rubygems'
require 'bundler/setup'
require 'webrick'
require 'optparse'

require File.expand_path("../../aha-services.rb", __FILE__)

options = {
  port: 3030
}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: proxy_server [OPTIONS]"
  opt.separator  ""
  opt.separator  "Options"

  opt.on("-p","--port PORT","which TCP port the server should run on (3030 by default)") do |port|
    options[:port] = port.to_i
  end

  opt.on("-h","--help","help") do
    puts opt_parser
    return
  end
end

opt_parser.parse!

server = WEBrick::HTTPServer.new(:Port => options[:port])
server.mount "/questions", WebForm
trap "INT" do server.shutdown end
server.start
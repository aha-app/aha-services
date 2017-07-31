require "rack"
require File.expand_path("../lib/proxy/server", __FILE__)

run ProxyApp

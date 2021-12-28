module AhaServices
  module Networking
    class VerifyNetAdapter < Faraday::Adapter::NetHttp
      def self.request_class
        @request_class ||= Net::HTTP
      end

      def self.request_class=(klass)
        @request_class = klass
      end

      def net_http_connection(env)
        klass = self.class.request_class
        port = env[:url].port || (env[:url].scheme == 'https' ? 443 : 80)
        klass.new(env[:url].hostname, port)
      end
    end
  end
end

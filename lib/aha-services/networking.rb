module Networking
  # Public: Lazily loads the Faraday::Connection for the current Service
  # instance.
  #
  # options - Optional Hash of Faraday::Connection options.
  #
  # Returns a Faraday::Connection instance.
  def http(options = {})
    @http ||= begin
      self.class.default_http_options.each do |key, sub_options|
        sub_hash = options[key] ||= {}
        sub_options.each do |sub_key, sub_value|
          sub_hash[sub_key] ||= sub_value
        end
      end
      options[:ssl][:ca_file] ||= ca_file

      Faraday.new(options) do |b|
        b.request options[:encoding] || :url_encoded
        faraday_builder(b)
        b.adapter *(options[:adapter] || :net_http)
        b.use(HttpReporter, self)
      end
    end
  end
  
  # Override this to install additional middleware.
  def faraday_builder(builder)
  end
  
  # Reset the HTTP connection so it can be recreated with new options.
  def http_reset
    @http = nil
  end
  
  # Gets the path to the SSL Certificate Authority certs.  These were taken
  # from: http://curl.haxx.se/ca/cacert.pem
  #
  # Returns a String path.
  def ca_file
    @ca_file ||= File.expand_path('../../config/cacert.pem', __FILE__)
  end
  
  # Public: Makes an HTTP GET call.
  #
  # url     - Optional String URL to request.
  # params  - Optional Hash of GET parameters to set.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_get("http://github.com")
  #   # => <Faraday::Response>
  #
  #   # GET http://github.com?page=1
  #   http_get("http://github.com", :page => 1)
  #   # => <Faraday::Response>
  #
  #   http_get("http://github.com", {:page => 1},
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_get "http://github.com" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1
  #     req.headers['Accept'] = 'application/json'
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_get(url = nil, params = nil, headers = nil)
    check_ssl do
      http.get do |req|
        req.url(verify_url(url))    if url
        req.params.update(params)   if params
        req.headers.update(headers) if headers
        yield req if block_given?
      end
    end
  end
  
  # Public: Makes an HTTP POST call.
  #
  # url     - Optional String URL to request.
  # body    - Optional String Body of the POST request.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_post("http://github.com/create", "foobar")
  #   # => <Faraday::Response>
  #
  #   http_post("http://github.com/create", "foobar",
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_post "http://github.com/create" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1 # http://github.com/create?page=1
  #     req.headers['Content-Type'] = 'application/json'
  #     req.body = {:foo => :bar}.to_json
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_post(url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?
    http_method :post, url, body, headers, &block
  end
  
  def http_put(url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?
    http_method :put, url, body, headers, &block
  end

  def http_patch(url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?
    http_method :patch, url, body, headers, &block
  end

  def http_delete(url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?
    http_method :delete, url, body, headers, &block
  end

  # Public: Makes an HTTP call.
  #
  # method  - Symbol of the HTTP method.  Example: :put
  # url     - Optional String URL to request.
  # body    - Optional String Body of the POST request.
  # headers - Optional Hash of HTTP headers to set.
  #
  # Examples
  #
  #   http_method(:put, "http://github.com/create", "foobar")
  #   # => <Faraday::Response>
  #
  #   http_method(:put, "http://github.com/create", "foobar",
  #     'Accept': 'application/json')
  #   # => <Faraday::Response>
  #
  #   # Yield the Faraday::Response for more control.
  #   http_method :put, "http://github.com/create" do |req|
  #     req.basic_auth("username", "password")
  #     req.params[:page] = 1 # http://github.com/create?page=1
  #     req.headers['Content-Type'] = 'application/json'
  #     req.body = {:foo => :bar}.to_json
  #   end
  #   # => <Faraday::Response>
  #
  # Yields a Faraday::Request instance.
  # Returns a Faraday::Response instance.
  def http_method(method, url = nil, body = nil, headers = nil)
    block = Proc.new if block_given?

    check_ssl do
      http.send(method) do |req|
        req.url(verify_url(url))    if url
        req.headers.update(headers) if headers
        req.body = body             if body
        block.call req if block
      end
    end
  end
  
  #
  # Make sure that user provided URLs cannot be used to attack any internal
  # services. We reject any that resolve to a local address.
  #
  def verify_url(url_to_check)
    uri = URI.parse(url_to_check)
    
    if (verified = @@verified_urls[uri.host]) == false
      raise AhaService::InvalidUrlError, "Invalid local address #{uri.host}"
    elsif verified
      return url_to_check
    end
    
    ip_to_check = IPSocket::getaddress(uri.host)
    @@prohibited_addresses.each do |addr|
      if addr === ip_to_check
        @@verified_urls[uri.host] = false
        raise AhaService::InvalidUrlError, "Invalid local address #{uri.host}"
      end
    end
    
    @@verified_urls[uri.host] = true
    url_to_check
  end
  
  # URLs that we have already checked. Hash of address to true/false if the 
  # URL is valid.
  @@verified_urls = {}
  
  # CIDR ranges that could be the local network and are prohibited.
  @@prohibited_addresses = [
      "0.0.0.0/8",
      "255.255.255.255/32",
      "127.0.0.0/8",
      "10.0.0.0/8",
      "169.254.0.0/16",
      "172.16.0.0/12",
      "192.168.0.0/16",
      "224.0.0.0/4",
      "fc00::/7",
      "fe80::/10"].collect do |a|
      IPAddr.new(a)
    end
  
  # Public: Checks for an SSL error, and re-raises a Services configuration error.
  #
  # Returns nothing.
  def check_ssl
    yield
  rescue OpenSSL::SSL::SSLError => e
    raise_config_error "Invalid SSL certificate"
  end
  
  def reportable_http_env(env, time)
    "#{env[:method].to_s.upcase} #{env[:url]} -- (#{"%.02fs" % [Time.now - time]}) #{env[:status]} #{env[:body]} #{env[:response_headers].inspect}"
  end
  
  class HttpReporter < ::Faraday::Response::Middleware
    def initialize(app, service = nil)
      super(app)
      @service = service
      @time = Time.now
    end

    def on_complete(env)
      #@service.receive_http(@service.reportable_http_env(env, @time))
      @service.logger.debug @service.reportable_http_env(env, @time)
    end
  end
end

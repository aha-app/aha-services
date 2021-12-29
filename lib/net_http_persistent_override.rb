class Net::HTTP::Persistent
  def self.request_class
    @request_class ||= Net::HTTP
  end

  def self.request_class=(klass) # rubocop:disable Style/TrivialAccessors
    @request_class = klass
  end

  def http_class
    self.class.request_class
  end
end

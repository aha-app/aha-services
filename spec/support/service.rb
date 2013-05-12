def service(klass, event_or_data, data, payload=nil)
  event = nil
  if event_or_data.is_a?(Symbol)
    event = event_or_data
  else
    payload = data
    data    = event_or_data
    event   = :create_feature
  end

  service = klass.new(event, data, payload)
  #service.http :adapter => [:test, @stubs]
  service
end
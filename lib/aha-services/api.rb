module Api
  def allocate_api_client
    AhaApi::Client.new(:domain => "a")
  end
end
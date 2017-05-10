class AhaServices::P2PM < AhaService
  title "P2 Process Maker"
  caption "Send features and requirements to Process Maker"
  service_name "p2_pm"
  
  string :server_url, description: "Server URL for authorizing user"
  string :client_id, desciption: "OAuth Client ID."
  password :client_secret, description: "OAuth Client Secret."
  string :user_name, description: "Enter the user name for your PM account."
  password :user_password, description: "Enter the password for your PM account."
  
  include P2PMCommon
end
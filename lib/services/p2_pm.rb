class AhaServices::P2PM < AhaService
  title "P2 Process Maker"
  caption "Send features and requirements to Process Maker"
  service_name "p2_pm"
  
  string :server_url, description: "Server URL for authorizing user"
  string :user_name, description: "Enter the user name for your PM account."
  password :user_password, description: "Enter the password for your PM account."
  string :base_url, description: "Base URL for PM interaction"

  include P2PMCommon
end
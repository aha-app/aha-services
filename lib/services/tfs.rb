class AhaServices::TFS < AhaService
  title "Team Foundation Server"
  caption "Send features and requirements to Microsoft Team Foundation Server"
  service_name "tfs_on_premise"
  
  string :server_url, description: "Server URL including the collection part of the path with no trailing slash. e.g. https://tfs.mycompany.com/tfs/DefaultCollection"
  string :user_name, description: "Enter the 'User name (secondary)' from the alternate credentials in TFS."
  password :user_password, description: "Enter the password from the alternate credentials in TFS."

  include TfsCommon
end

class AhaServices::TFS < AhaService
  title "Azure DevOps Server"
  caption "Send features and requirements to Microsoft Azure DevOps Server"
  service_name "tfs_on_premise"
  
  string :server_url, description: "Server URL including the collection part of the path with no trailing slash. e.g. https://tfs.mycompany.com/tfs/DefaultCollection"
  string :user_name, description: "Enter the user name for your Azure DevOps Server account."
  password :user_password, description: "Enter the password for your Azure DevOps Server account."

  include TfsCommon
end

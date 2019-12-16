class AhaServices::VSO < AhaService
  title "Azure DevOps Services"
  caption do |workspace_type|
    object =
      if workspace_type == "marketing_workspace"
        "activities"
      else
        "features"
      end
    "Send #{object} and requirements to Microsoft Azure DevOps Services (formerly VSTS)"
  end
  service_name "tfs"

  string :account_name, description: "The name of your Azure DevOps Services subdomain. e.g. if your Azure DevOps Services domain is https://fredwin.visualstudio.com or https://dev.azure.com/fredwin, then enter 'fredwin' here."
  string :user_name, description: "Enter your email address or username (if you use a personal access token this field is not used)."
  password :user_password, description: "Enter a personal access token from Azure DevOps Services."
  
  include TfsCommon
  
  callback_url description: "This url will be used to receive updates from Azure DevOps Services."
end

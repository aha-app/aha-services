class AhaServices::VSO < AhaService
  title "Visual Studio Team Services"
  caption "Send features and requirements to Microsoft Visual Studio Team Services"
  service_name "tfs"

  string :account_name, description: "The name of your Visual Studio subdomain. e.g. if your Visual Studio domain is https://mycompany.visualstudio.com, then enter 'mycompany' here."
  string :user_name, description: "Enter your email address or username (if you use a personal access token this field is not used)."
  password :user_password, description: "Enter a personal access token from Visual Studio Team Services."
  
  include TfsCommon
  
end
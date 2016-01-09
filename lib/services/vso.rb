class AhaServices::VSO < AhaService
  title "Visual Studio Team Services"
  caption "Send features and requirements to Microsoft Visual Studio Team Services"
  service_name "tfs"

  string :account_name, description: "The name of your Visual Studio subdomain. e.g. if your Visual Studio domain is https://mycompany.visualstudio.com, then enter 'mycompany' here."
  string :user_name, description: "Enter the 'User name (secondary)' from the alternate credentials in Visual Studio Team Services. This is not your email address."
  password :user_password, description: "Enter the password from the alternate credentials in Visual Studio Team Services."
  
  include TfsCommon
  
end
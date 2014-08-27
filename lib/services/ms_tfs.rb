class AhaServices::MSTFS < AhaService
  caption "Send features to Microsoft Team Foundation Server"

  string :account_name, description: "The name of your Visual Studio subdomain."
  string :user_name, description: "The name of the user used to access Visual Studio Online."
  string :user_password, description: "The password of the user used to access Visual Studio Online."

  install_button

  def receive_installed
    #meta_data.projects = project_resource.all
    puts workitem_resource.all
  end

protected
  def project_resource
    @project_resource ||= MSTFSProjectResource.new(self)
  end

  def workitem_resource
    @workitem_resource ||= MSTFSWorkItemResource.new(self)
  end
end

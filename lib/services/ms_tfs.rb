class AhaServices::MSTFS < AhaService
  caption "Send features to Microsoft Team Foundation Server"

  string :account_name, description: "The name of your Visual Studio subdomain."
  string :user_name, description: "The name of the user used to access Visual Studio Online."
  string :user_password, description: "The password of the user used to access Visual Studio Online."

  install_button

  select :project, description: "The project you want to create new features in.",
    collection: ->(meta_data, data) {
    meta_data.projects.collect do |project|
      [project.name, project.id]
    end
  }

  select :requirement_mapping, collection: [ [ "User Story", "User Story" ], [ "Requirement", "Requirement" ], [ "Product Backlog Item", "Product Backlog Item" ] ]

  def receive_installed
    meta_data.projects = project_resource.all
  end

  def receive_create_feature
    sync_feature
  end


  def sync_feature
    path = meta_data.projects.detect{ |project| data.project == project.id }.name
    # All fields required, exepct for maybe Description
    workitem = workitem_resource.create Hash[
      "System.Title" => payload.feature.name,
      "System.Description" => payload.feature.description.body,
      "System.WorkItemType" => "Feature",
      "System.AreaPath" => path,
      "System.IterationPath" => path,
      "System.State" => "New",
      "System.Reason" => "New Feature",
      "Microsoft.VSTS.Common.Priority" => 3
    ]
    #sync_requirements workitem, path
    sync_tasks workitem, path
  end

  def sync_requirements workitem, path
    payload.feature.requirements.each do |requirement|
      workitem_resource.create Hash[
        "System.Title" => requirement.name,
        "System.Description" => requirement.description.body,
        "System.WorkItemType" => data.requirement_mapping,
        "System.AreaPath" => path,
        "System.IterationPath" => path,
        "System.State" => "New",
        "System.Reason" => "New backlog item",
        "Microsoft.VSTS.Common.Priority" => 3
      ], [
        {
          :linkType => "System.LinkTypes.Hierarchy",
          :targetWorkItemId => -1,
          :sourceWorkItemId => workitem.id
        }
      ]
    end
  end

  def sync_tasks workitem, path
    puts
    puts payload.to_hash
    puts
    payload.feature.tasks.each do |task|
      workitem_resource.create Hash[
        "System.Title" => task.name
      ], [
        {
          :linkType => "System.LinkTypes.Hierarchy",
          :targetWorkItemId => -1,
          :sourceWorkItemId => workitem.id
        }
      ]
    end
  end

protected
  def project_resource
    @project_resource ||= MSTFSProjectResource.new(self)
  end

  def workitem_resource
    @workitem_resource ||= MSTFSWorkItemResource.new(self)
  end
end

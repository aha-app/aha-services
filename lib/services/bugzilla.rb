class AhaServices::Bugzilla < AhaService
  title "Bugzilla"
  caption do |workspace_type|
    object =
      if workspace_type == "marketing_workspace"
        "activities"
      else
        "features"
      end
    "Send #{object} and requirements to a Bugzilla installation"
  end

  string :server_url, description: "The URL of the Bugzilla installation, without trailing slash, e.g. https://landfill.bugzilla.org/bugzilla-tip"
  string :api_key, description: "The API key used to access the Bugzilla REST API."

  install_button

  select :product, description: "The product in which new bugs will be created", collection: ->(meta_data, data) {
    meta_data.products.map{|product| [product.name, product.id] } rescue []
  }

  select :component, description: "The component in which new bugs will be created", collection: ->(meta_data, data) {
    product = meta_data.products.find{|p| p.id.to_s == data.product } rescue nil
    product.components.map{|c| [c.name, c.id] } rescue []
  }

  def receive_installed
    meta_data.products = product_resource.get_enterable
    meta_data.defaults = bug_field_resource.get_defaults meta_data.products.map{|p| p.name }
  end

  def receive_create_feature
    bug_resource.create_from_feature payload.feature
  end

  def receive_update_feature
    bug_resource.update_from_feature payload.feature
  end

  protected

  def product_resource
    @product_resource ||= BugzillaProductResource.new(self)
  end

  def bug_resource
    @bug_resource ||= BugzillaBugResource.new(self)
  end

  def bug_field_resource
    @bug_field_resource ||= BugzillaBugFieldResource.new(self)
  end
end

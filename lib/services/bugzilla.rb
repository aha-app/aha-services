class AhaServices::Bugzilla < AhaService
  title "Bugzilla"
  caption "Send features and requirements to a Bugzilla installation"

  string :server_url, description: "The URL of the Bugzilla installation, without trailing slash, e.g. https://landfill.bugzilla.org/bugzilla-tip"
  string :api_key, description: "The API key used to access the Bugzilla REST API."

  install_button

  select :product, description: "The product in which new bugs will be created", collection: ->(meta_data, data) {
    meta_data.products.map{|product| [product.name, product.id] } rescue []
  }

  select :component, description: "The component in which new bugs will be created", collection: ->(meta_data, data) {
    product = meta_data.products.find{|p| p.id.to_s == data.product }
    product.components.map{|c| [c.name, c.id] } rescue []
  }

  def receive_installed
    meta_data.products = product_resource.get_enterable
    pp meta_data.products
  end

  protected

  def product_resource
    @product_resource ||= BugzillaProductResource.new(self)
  end
end

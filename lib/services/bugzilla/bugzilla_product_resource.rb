class BugzillaProductResource < BugzillaResource
  def get_enterable
    response = http_get bugzilla_url("product_enterable")
    body = process_response(response)
    params = {
      :ids => body.ids,
      :include_fields => "id,name,components.id,components.name"
    }
    response = http_get bugzilla_url("product"), params
    body = process_response(response)
    body.products
  end
end

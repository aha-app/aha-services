class MSTFSWorkItemResource < MSTFSResource

  ALL_QUERY = "SELECT [System.ID], [System.Title], [System.Description], [System.WorkItemType], [System.State] FROM WorkItems"

  def all
    prepare_request
    response = http_post mstfs_url("wit/queryresults"), { wiql: ALL_QUERY }.to_json
    ids = collect_ids_from_query response
    response = http_get mstfs_url("wit/workitems?ids=#{ids.join(",")}")
    found_resource(response).value.collect do |workitem|
      {
        id: workitem.id,
        name: field_by_refName( workitem.fields, "System.Title" ),
        description: field_by_refName( workitem.fields, "System.Description" ),
        workItemType: field_by_refName( workitem.fields, "System.WorkItemType" )
      }
    end
  end

protected

  def field_by_refName fields, refName
    f = fields.find{ |fieldObject| fieldObject.field.refName == refName }
    f ? f.value : nil
  end

  def collect_ids_from_query response
    return [] unless response.status == 200
    hashie = found_resource(response)
    hashie.results.collect do |entity|
      entity.sourceId
    end
  end
end

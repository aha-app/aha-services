class TrelloChecklistResource < TrelloResource
  def find_item(checklist_id, checklist_item_id)
    prepare_request
    response = http_get trello_url("checklists/#{checklist_id}/checkitems/#{checklist_item_id}")
    found_resource(response).tap do |resource|
      resource&.merge!(checklist_id: checklist_id)
    end
  end

  def find_by_name(checklist_name, card)
    prepare_request
    response = http_get trello_url("cards/#{card.id}/checklists")
    process_response(response, 200) do |checklists|
      return checklists.find { |checklist| checklist.name == checklist_name }
    end
  end

  def create(new_checklist)
    prepare_request
    response = http_post trello_url("checklists"), new_checklist.to_json
    process_response(response, 200) do |checklist|
      return checklist
    end
  end

  def create_item(new_checklist_item)
    prepare_request
    response = http_post trello_url("checklists/#{new_checklist_item[:idChecklist]}/checkItems"),
      new_checklist_item.to_json
    process_response(response, 200) do |checklist_item|
      return checklist_item.merge(checklist_id: new_checklist_item[:idChecklist])
    end
  end

  def update_item(card, updated_checklist_item)
    prepare_request

    response = found_resource(
      http_put(
        trello_url(
          "cards/#{card.id}/checklist/#{updated_checklist_item[:idChecklistCurrent]}/checkItem/#{updated_checklist_item[:idCheckItem]}"
        ),
        updated_checklist_item.to_json
      )
    )

    if response
      response.merge(checklist_id: updated_checklist_item[:idChecklistCurrent])
    end
  end
end

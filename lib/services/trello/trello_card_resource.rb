class TrelloCardResource < TrelloResource
  def find_by_id(id)
    prepare_request
    response = http_get trello_url("cards/#{id}")
    found_resource(response)
  end

  def create(new_card)
    prepare_request
    response = http_post trello_url("cards"), new_card.to_json
    process_response(response, 201) do |card|
      return card
    end
  end

  def update(id, updated_card)
    prepare_request
    response = http_put trello_url("cards/#{id}"), updated_card.to_json
    found_resource(response)
  end
end

class TrelloLabelResource < TrelloResource
  def all_for_card(card_id)
    prepare_request
    response = http_get trello_url("cards/#{card_id}/labels")
    found_resource(response)
  end
end
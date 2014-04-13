class TrelloBoardResource < TrelloResource
  def all
    prepare_request
    response = http_get trello_url("members/#{@service.data.username_or_id}/boards")
    found_resource(response)
  end
end

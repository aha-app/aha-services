class TrelloAttachmentResource < TrelloResource
  def all_for_card(card_id)
    prepare_request
    response = http_get trello_url("cards/#{card_id}/attachments")
    found_resource(response)
  end

  def upload(attachment, card_id)
    prepare_request
    response = http_post trello_url("cards/#{card_id}/attachments"),
                         { url: attachment.download_url }.to_json
  end
end

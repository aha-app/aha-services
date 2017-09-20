class TrelloCardResource < TrelloResource
  def find_by_id(id)
    prepare_request
    response = http_get trello_url("cards/#{id}")
    found_resource(response)
  end

  def create(new_card)
    prepare_request
    response = http_post trello_url("cards"), new_card.to_json
    process_response(response, 200) do |card|
      return card
    end
  end

  def update(id, updated_card)
    prepare_request
    response = http_put trello_url("cards/#{id}"), updated_card.to_json
    found_resource(response)
  end

  def create_comment(id, text)
    prepare_request
    response = http_post trello_url("cards/#{id}/actions/comments"),
      { text: text }.to_json
    process_response(response, 200)
  end

  def create_webhook(card_id)
    prepare_request
    response = http_post trello_url("webhooks"),
      { callbackURL: "#{@service.data.callback_url}",
        idModel: card_id }.to_json
    process_response(response, 200)
  rescue Exception => e
    # Don't fail if we can't create webhook.
    logger.warn(e.message)
  end

  def add_label(id, text, color)
    prepare_request
    escaped_text = CGI::escape(text)
    response = http_post trello_url("cards/#{id}/labels?color=#{color}&name=#{escaped_text}")
    process_response(response, 200)
  end

  def remove_label(card_id, label_id)
    prepare_request
    response = http_delete trello_url("cards/#{card_id}/idLabels/#{label_id}")
    process_response(response, 200)
  end

end

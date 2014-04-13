require "reverse_markdown"

class AhaServices::Trello < AhaService
  title "Trello"

  string :username_or_id, description: "Use your Trello username or id, not your email address."
  install_button
  select :board, collection: ->(meta_data) {
    meta_data.boards.sort_by(&:name).collect do |board|
      [board.name, board.id]
    end
  }
  internal :feature_status_mapping
  select :list_for_new_features, collection: ->(meta_data) {
    data.board and data.board.lists.collect do |list|
      [list.name, list.id]
    end
  }
  select :create_features_at,
    collection: -> { [["top", "top"], ["bottom", "bottom"]] },
    description: "Should the newly created features appear at the top or at the bottom of the Trello list."

  def receive_installed
    meta_data.boards = board_resource.all
  end

  def receive_create_feature
    create_or_update_trello_card(payload.feature)
  end

  def receive_update_feature
    create_or_update_trello_card(payload.feature)
  end

  def create_or_update_trello_card(feature)
    if card = existing_card_integrated_with(feature)
      update_card(card.id, feature)
    else
      create_card_for(feature)
    end
  end

  def existing_card_integrated_with(feature)
    if card_id = get_integration_field(feature.integration_fields, "id")
      card_resource.find_by_id(card_id)
    end
  end

  def create_card_for(feature)
    card = card_resource.create(
      name: resource_name(feature),
      desc: ReverseMarkdown.convert(feature.description),
      pos: data.create_features_at,
      due: "null",
      idList: list_id_by_feature_status(feature.status)
    )
    integrate_feature_with_trello_card(feature, card)
    card_resource.create_comment card.id, "Created from Aha! #{feature.url}"
  end

  def update_card(card_id, feature)
    card_resource
      .update card_id,
              name: resource_name(feature),
              desc: ReverseMarkdown.convert(feature.description),
              idList: list_id_by_feature_status(feature.status)
  end

protected

  def board_resource
    @board_resource ||= TrelloBoardResource.new(self)
  end

  def card_resource
    @card_resource ||= TrelloCardResource.new(self)
  end

  def list_id_by_feature_status(status)
    "dummy_list_id"
  end

  def integrate_feature_with_trello_card(feature, card)
    api.create_integration_fields(
      "features",
      feature.reference_num,
      self.class.service_name,
      {
        id: card.id,
        url: "https://trello.com/c/#{card.id}"
      }
    )
  end

end

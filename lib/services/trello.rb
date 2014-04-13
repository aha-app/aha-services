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
      card = create_card_for(feature)
    end
    update_requirements(card, feature.requirements)
    update_attachments(card, feature)
  end

  def update_requirements(card, requirements)
    requirements and requirements.each do |requirement|
      create_or_update_trello_checklist_item(card, requirement)
      update_attachments(card, requirement)
    end
  end

  def create_or_update_trello_checklist_item(card, requirement)
    if checklist_item = existing_checklist_item_integrated_with(requirement)
      update_checklist_item(checklist_item, requirement, card)
    else
      create_checklist_item_for(requirement, card)
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
      desc: ReverseMarkdown.convert(feature.description.body),
      pos: data.create_features_at,
      due: "null",
      idList: data.list_for_new_features
    )
    integrate_feature_with_trello_card(feature, card)
    card_resource.create_comment card.id, "Created from Aha! #{feature.url}"
    card
  end

  def update_card(card_id, feature)
    card_resource
      .update card_id,
              name: resource_name(feature),
              desc: ReverseMarkdown.convert(feature.description.body),
              idList: list_id_by_feature_status(feature.status)
  end

  def existing_checklist_item_integrated_with(requirement)
    if (checklist_id = get_integration_field(requirement.integration_fields, "checklist_id")) &&
       (checklist_item_id = get_integration_field(requirement.integration_fields, "id"))
      checklist_resource.find_item(checklist_id, checklist_item_id)
    end
  end

  def create_checklist_item_for(requirement, card)
    checklist_name = "Requirements"
    unless checklist = checklist_resource.find_by_name(checklist_name, card)
      checklist = checklist_resource.create idCard: card.id,
                                            name: checklist_name
    end
    checklist_item =
      checklist_resource.create_item idChecklist: checklist.id,
                                     name: checklist_item_name(requirement)
    integrate_requirement_with_trello_checklist_item(requirement, checklist_item)
  end

  def update_checklist_item(checklist_item, requirement, card)
    checklist_resource.update_item card,
                                   idChecklistCurrent: checklist_item.checklist_id,
                                   idCheckItem: checklist_item.id,
                                   name: checklist_item_name(requirement)
  end

  def update_attachments(card, resource)
    aha_attachments = resource.attachments.dup |
      resource.description.attachments.dup
    upload_attachments(new_aha_attachments(aha_attachments, card), card)
  end

  def new_aha_attachments(aha_attachments, card)
    attachment_resource.all_for_card(card.id).each do |trello_attachment|
      aha_attachments.reject! do |aha_attachment|
        attachments_match(aha_attachment, trello_attachment)
      end
    end
    aha_attachments
  end

  def attachments_match(aha_attachment, trello_attachment)
    aha_attachment.file_name == trello_attachment.url and
      aha_attachment.file_size.to_i == trello_attachment.bytes.to_i
  end

  def upload_attachments(attachments, card)
    attachments.each do |attachment|
      attachment_resource.upload(attachment, card.id)
    end
  end

protected

  def board_resource
    @board_resource ||= TrelloBoardResource.new(self)
  end

  def card_resource
    @card_resource ||= TrelloCardResource.new(self)
  end

  def checklist_resource
    @checklist_resource ||= TrelloChecklistResource.new(self)
  end

  def attachment_resource
    @attachment_resource ||= TrelloAttachmentResource.new(self)
  end

  def list_id_by_feature_status(status)
    "list_id_from_feature_status"
  end

  def checklist_item_name(requirement)
    [requirement.name, ReverseMarkdown.convert(requirement.description.body)]
      .compact.join(". ")
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

  def integrate_requirement_with_trello_checklist_item(requirement, checklist_item)
    api.create_integration_fields(
      "requirements",
      requirement.reference_num,
      self.class.service_name,
      {
        id: checklist_item.id,
        checklist_id: checklist_item.checklist_id
      }
    )
  end

end

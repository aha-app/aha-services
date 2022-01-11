require "reverse_markdown"

class AhaServices::Trello < AhaService
  caption "Send features to a Trello board"

  oauth_button request_token_url: "https://trello.com/1/OAuthGetRequestToken",
    access_token_url: "https://trello.com/1/OAuthGetAccessToken",
    authorize_url: "https://trello.com/1/OAuthAuthorizeToken",
    parameters: {name: "Aha! Integration", scope: "read,write", expiration: "never"}
  install_button
  select :board, collection: ->(meta_data, data) {
    meta_data.boards.sort_by(&:name).collect do |board|
      [board.name, board.id]
    end
  }
  internal :feature_status_mapping
  select :list_for_new_features, collection: ->(meta_data, data) {
    meta_data.boards.detect {|b| b[:id] == data.board }.lists.collect do |list|
      [list.name, list.id]
    end
  }
  select :create_features_at,
    collection: [["Top", "top"], ["Bottom", "bottom"]],
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

  def receive_webhook
    if payload.model and payload.model.idList
      new_list_id = payload.model.idList
      if url = webhook_feature_url(payload.model.id)
        api.put(url, { workflow_status: data.feature_statuses[new_list_id.to_s] })
      end
    end
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
    due_date = unless feature.release.parking_lot
      feature.due_date || feature.release.release_date
    end

    card = card_resource.create(
      name: resource_name(feature),
      desc: reverse_markdown_convert(feature.description.body),
      pos: data.create_features_at,
      due: end_of_work_day(due_date),
      idList: data.list_for_new_features
    )
    webhook = card_resource.create_webhook(card.id)
    integrate_feature_with_trello_card(feature, card)
    card_resource.create_comment card.id, "Created from Aha! #{feature.url}"
    card
  end

  def end_of_work_day(date_string)
    if date_string
      Time.parse(date_string).utc.beginning_of_day + (17*60*60)
    else
      nil
    end
  end

  def update_card(card_id, feature)
    due_date = feature.due_date || feature.release.release_date

    card_resource
      .update card_id,
        name: resource_name(feature),
        desc: reverse_markdown_convert(feature.description.body),
        due: end_of_work_day(due_date)
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
    uri = URI.parse(trello_attachment.url)
    trello_filename = File.basename(uri.path)
    # Trello has modified its attachment naming normalization, but it is not
    # clear whether they updated all previous attachments, so we are checking
    # against the normalized value and the raw value for backwards
    # compatibility
    (trelloize_filename(aha_attachment.file_name) == trello_filename ||
      aha_attachment.file_name == trello_filename
    )
  end

  def trelloize_filename(filename)
    filename.gsub!(/[ *\\\"\']/, "_")

    # This method used to call URI.escape but in Ruby 3 this method was removed.
    # In an effort to preserve the same behavior, which replacements such as CGI.escape
    # do not match exactly, we replicate the same logic from URI.escape here.
    # See https://github.com/ruby/ruby/blob/f69aeb83146be640995753667fdd6c6f157527f5/lib/uri/rfc2396_parser.rb#L300
    unsafe_characters = Regexp.new("[^\\-_.!~*'()a-zA-Z\\d;/?:@&=+$,\\[\\]]")

    filename.gsub(unsafe_characters) do |match|
      escaped_filename = ''

      match.each_byte do |character|
        escaped_filename << sprintf('%%%02X', character)
      end

      escaped_filename
    end.force_encoding(Encoding::US_ASCII)
  end

  def upload_attachments(attachments, card)
    attachments.each do |attachment|
      attachment_resource.upload(attachment, card.id)
    end
  end

  def create_card_webhook(card_id)
    card_resource.create_webhook(card_id)
  end

protected

  def reverse_markdown_convert(text)
    Nokogiri::HTML.parse(ReverseMarkdown.convert(text)).text
  end

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
    data.feature_statuses.invert[status]
  end

  def checklist_item_name(requirement)
    [requirement.name, reverse_markdown_convert(requirement.description.body)]
      .compact.join(". ")
  end

  def webhook_feature_url(card_id)
    begin
      result = api.search_integration_fields(data.integration_id, "id", card_id)['records'].first
    rescue AhaApi::NotFound
      return nil # Ignore cards that we don't have Aha! features for.
    end

    if result && result.feature
      resource = result.feature
    elsif result && result.requirement
      resource = result.requirement
    else
      logger.info("Unhandled resource type")
      return nil
    end

    resource.resource
  end

  def integrate_feature_with_trello_card(feature, card)
    api.create_integration_fields(
      "features",
      feature.reference_num,
      data.integration_id,
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
      data.integration_id,
      {
        id: checklist_item.id,
        checklist_id: checklist_item.checklist_id
      }
    )
  end

end

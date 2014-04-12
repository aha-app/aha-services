require "reverse_markdown"

class AhaServices::Trello < AhaService
  title "Trello"

  string :username_or_id, description: "Use your Trello username or id, not your email address."
  install_button
  select :board, collection: ->(meta_data) do
    meta_data.boards.sort_by(&:name).collect { |board|
      [board.name, board.id]
    }
  end
  internal :feature_status_mapping
  select :list_for_new_features, collection: ->(meta_data) do
    meta_data.lists.collect { |list|
      [list.name, list.id]
    }
  end
  select :create_features_at,
    collection: -> do
      [["top", "top"], ["bottom", "bottom"]]
    end,
    description: "Should the newly created features appear at the top or at the bottom of the Trello list."

  def receive_installed
  end

  def receive_create_feature
  end

  def receive_update_feature
  end

  def receive_create_release
  end

  def receive_update_release
  end

  # These methods are exposed here so they can be used in the callback and
  # import code.
  def get_issue(issue_id)
  end

  def search_issues(params)
  end

end

class TrelloBoardResource < TrelloResource
  def all
    prepare_request
    response = http_get trello_url("members/me/boards?lists=all")
    Array(found_resource(response)).collect do |board|
      {id: board.id, name: board.name, lists: board.lists.collect {|list| 
        if list.closed
          nil
        else
          {id: list.id, name: list.name}
        end
      }.compact}
    end
  end
end

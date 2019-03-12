class AhaServices::Zendesk < AhaService
  caption do |workspace_type|
    object =
      case workspace_type
      when "multi_workspace" then "ideas or requests"
      when "product_workspace" then "ideas"
      when "marketing_workspace" then "requests"
      end
    "Receive #{object} from a Zendesk helpdesk"
  end
  category "Ideas capture"
end

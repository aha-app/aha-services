class AhaServices::Confluence < AhaService
  caption 'Embed a live Aha! roadmap, report, or presentation in your Confluence page.'

  # Integrations in this category do not directly receive or send data but are rather
  # presentational integrations from our shared webpages.
  category 'Knowledge management'

  confluence_button

  def receive_wiki
    # Placeholder class method allowing the service to be included in product services.
  end
end

# Utility routines specific to Aha! data.
module Helpers
  
  def resource_name(resource)
    if resource.name.present?
      resource.name
    else
      description_to_title(resource.description.body)
    end
  end

  # Convert HTML to formatted plain text.
  def html_to_plain(html)
    converter = PlainDavid::Strategies::PlainStrategy.new(html)
    converter.convert!(nil)
  end
  
  def reference_num_to_resource_type(reference_num)
    if reference_num =~ /-R-\d+$/ or reference_num =~ /-R-PL$/
      "releases"
    elsif reference_num =~ /-\d+-\d+$/
      "requirements"
    else
      "features"
    end
  end

private

  # Convert a description field to a title - e.g. for requirements which
  # do not have a title.
  def description_to_title(body)
    body = body.dup
    # Truncate at end of paragraph or sentence
    body.gsub!(/\. .*/, "")
    body.gsub!(/<\/p>.*/, "")
    body.gsub!(/<\/?[^>]*>/, "")
    body.gsub!(/[\t\n\r]/, " ") # Remove newlines.
    body = HTMLEntities.new.decode(body) # Decode HTML entities.
    trailer = "..." if body.length > 200
    "#{body[0..200]}#{trailer}"
  end

end
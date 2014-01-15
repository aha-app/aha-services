# Utility routines specific to Aha! data.
module Helpers
  
  # Convert a description field to a title - e.g. for requirements which
  # do not have a title.
  def description_to_title(body)
    body = body.dup
    # Truncate at end of paragraph or sentence
    body.gsub!(/\. .*/, "")
    body.gsub!(/<\/p>.*/, "")
    body.gsub!(/<\/?[^>]*>/, "")
    body.gsub!(/[\t\n\r]/, " ") # Remove newlines.
    trailer = "..." if body.length > 200
    "#{body[0..200]}#{trailer}"
  end
  
  # Convert HTML to formatted plain text.
  def html_to_plain(html)
    converter = PlainDavid::Strategies::PlainStrategy.new(html)
    converter.convert!(nil)
  end
  
end
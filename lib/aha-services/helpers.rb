require 'plain-david'
require 'redcarpet'
require 'securerandom'

# Use a custom table renderer to match Aha table style, so incoming markdown is transformed correctly
class AhaTableRender < Redcarpet::Render::HTML
  def table(header, body)
    "<table class='mce-item-table'>" + 
      "<tbody>#{header}#{body}</tbody>" +
    "</table>"
  end
  
  def table_cell(content, alignment)
    "<td>#{content}</td>"
  end
end

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

  def links_to_keys(html)
    keys = {}
    html.gsub( html_link_pattern ) do |match|
      link = Regexp.last_match[1]
      text = Regexp.last_match[2]
      key_id = SecureRandom.hex
      keys[key_id] = {link: link, text: html_to_plain(text)}
      key_id
    end
    [html, keys]
  end

  def keys_to_links(html, keys)
    keys.each do |key_id, data|
      html = html.gsub(key_id) do |match|
        "<a href=#{data[:link]}>#{data[:text]}</a>"
      end
    end
    html
  end

  def keys_to_links_slack(html, keys)
    keys.each do |key_id, data|
      html = html.gsub(key_id) do |match|
        slack_link(data[:link], data[:text])
      end
    end
    html
  end
  
  def html_to_markdown(html, github_style = false)
    ReverseMarkdown.convert(html, unknown_tags: 
    :bypass, github_flavored: github_style)
  end
  
  def html_to_slack_markdown(html)
    html = (html || "").to_s.gsub(/\n$/, '').gsub(/<del[^>]*>([^<]*)<\/del>/, '')
    # Keep slack links though plain
    html, keys = links_to_keys(html)
    html_to_plain(html)
    html = keys_to_links_slack(html, keys)
    HTMLEntities.new.decode(html)
  end

  def html_to_hipchat_markdown(html)
    html = (html || "").to_s.gsub(/\n$/, '').gsub(/<del[^>]*>([^<]*)<\/del>/, '')

    html, keys = links_to_keys(html)
    html_to_plain(html)
    html = keys_to_links(html, keys)
    HTMLEntities.new.decode(html)
  end

  def markdown_to_html(markdown)
    converter = Redcarpet::Markdown.new(AhaTableRender.new, autolink: true, tables: true)
    converter.render(markdown)
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

  def html_link_pattern
      / <a (?:.*?) href=['"](.+?)['"] (?:.*?)> (.+?) <\/a> /x
  end

  def slack_link(link, text = nil)
    out = "<#{link}"
    out << "|#{text}" if text && !text.empty?
    out << ">"

    return out
  end

end
require "reverse_markdown"

class GithubMarkdownConverter
  COLSPAN_CELL = "\uFEFF".freeze
  ROWSPAN_CELL = "\uFEFF\uFEFF".freeze

  def convert_html_from_aha(html)
    preprocess html
    markdown = converter.convert(html)
    postprocess markdown
  end

  def preprocess(html)
    # replace special entities.
    html.gsub!(/&(mdash|#8212);/, '---')
    html.gsub!(/&(ndash|#8211);/, '--')
    # replace non-breaking spaces
    html.gsub!(/&(nbsp|#160);/, ' ')
  end

  def postprocess(markdown)
    # github handles code blocks correctly. ReverseMarkdown incorrectly
    # escapes codeblocks.
    markdown.gsub(/`[^`]+`/) do |code_point|
      code_point.gsub('\\_', "_").gsub('\\*', "*")
    end
  end

  def converter
    ReverseMarkdown.new(unknown_tags: :bypass, github_flavored: true) do |c|
        # Github tables look like:
        #
        # header 1|header 2|header 3
        # --------|--------|--------
        # content|content|content
        AhaServices::Services::Common::MarkdownTableConverter.register(
          c,
          underline_header: true,
          end_caps: false
        )
    end
  end 
end

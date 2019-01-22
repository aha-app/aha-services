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
      c.register(:table, Table.new)
      c.register(:tr, Tr.new)
      c.register(:td, Td.new)
      c.register(:th, Th.new)
    end
  end 

  # rubocop:disable Style/ClassVars
  class TableBase < ReverseMarkdown::Converters::Base
    def table_did_begin
      super
      @@next_row_spans = {}
      @@inserted_col_spans = 0
    end

    def cleanup_table_cell(content)
      clean_content = content.strip.gsub(/\n{2,}/, "\n" + '\\\\\\' + "\n")

      # Don't allow a completely empty cell because that will look like a header.
      if clean_content.empty? || clean_content.gsub("&nbsp;", "").strip.empty?
        " "
      else
        clean_content
      end
    end

    def first_col?(node)
      node == node.parent.first_element_child
    end

    def treat_elements(node)
      # @table_did_begin = false
      node.element_children.each_with_index.inject('') do |memo, pair|
        child = pair[0]
        index = pair[1]
        memo << treat(child, index)
      end
    end
  end

  # Github tables look like:
  #
  # header 1|header 2|header 3
  # --------|--------|--------
  # content|content|content
  class Table < TableBase
    def convert(node, index)
      table_did_begin

      rows = node.element_children.flat_map do |child|
        if child.name == "tr"
          [child]
        elsif %w[tbody thead].include?(child.name)
          child.element_children
        end
      end

      row_content = rows.each_with_index.map do |row, row_index|
        treat(row, row_index)
      end

      if row_content.any?
        # Create the first row (header)
        content = "\n\n" << row_content[0]
        # Now github requires an underline in the form of -|-|- matching
        # the header columns.
        content << "-" << row_content[0].scan(/\|/).join("-") << "-\n"
        # And then we can add the rest of the rows.
        row_content[1..-1].each do |row|
          content << row
        end
        content << "\n"
      end

      table_did_end
      content
    end
  end

  class Tr < TableBase
    def convert(node, index)
      next_row_spans = {}

      # As we go down each row check if the prior row set some rowspan info.
      # If it did then insert extra cells at the given index and decrement the
      # rowspan count in the structure.
      if @@next_row_spans.any?
        tds = node.element_children

        @@next_row_spans.each do |td_index, rs|
          if rs > 2
            next_row_spans[td_index] = rs - 1
          end

          td = tds[td_index]

          if td
            td.add_previous_sibling("<td>#{ROWSPAN_CELL}</td>")
          else
            node.add_child("<td>#{ROWSPAN_CELL}</td>")
          end

          tds = node.element_children
        end
      end

      @@next_row_spans = next_row_spans
      @@inserted_col_spans = 0

      content = treat_elements(node).strip
      content = "#{content}\n"

      content
    end
  end

  class Td < TableBase
    def convert(node, index)
      content = cleanup_table_cell(treat_children(node))
      content = "#{first_col?(node) ? '' : '|'}#{content}"

      # For each spanned column add a column
      colspan = node['colspan'].to_i
      if colspan > 1
        (colspan - 1).times do
          content << "#{COLSPAN_CELL}|"
        end
      end

      # For each spanned row put the information in a variable to be used by
      # the next row
      rowspan = node['rowspan'].to_i
      if rowspan > 1
        iindex = index + @@inserted_col_spans
        @@next_row_spans[iindex] = rowspan

        if colspan > 1
          (colspan - 1).times do |n|
            @@next_row_spans[iindex + n + 1] = rowspan
          end
        end
      end

      # Keep track of the number of inserted cells so that we can adjust the
      # rowspan index (above) on the next cell with a rowspan
      @@inserted_col_spans += (colspan - 1) if colspan > 1

      content
    end
  end
  # rubocop:enable Style/ClassVars

  class Th < TableBase
    def convert(node, index)
      content = cleanup_table_cell(treat_children(node))
      "#{first_col?(node) ? '' : '|'}#{content}"
    end
  end
end

require "reverse_markdown"

module AhaServices
  module Services
    module Common
      # Implement table handling for ReverseMarkdown conversion.
      # Usage:
      #   ReverseMarkdown.new do |c|
      #     MarkdownTableConverter.register(c)
      #   end
      #
      # Takes options to support different table syntax between provides. The
      # default is to produce tables like this:
      # 
      # | cell | cell | cell |
      # | cell | cell | cell |
      #
      # But jira likes headers double capped so register(c, header_cap: '||')
      #
      # || header || header || header ||
      # | cell     | cell    | cell    |
      #
      # And Github likes its headers underlined and no end caps so register(c,
      # end_caps: false, underline_header: true)
      #
      # header | header | header
      # -------|--------|-------
      # cell   | cell   | cell
      #
      module MarkdownTableConverter
        COLSPAN_CELL = "\uFEFF".freeze
        ROWSPAN_CELL = "\uFEFF\uFEFF".freeze

        def register(converter, cap: "|", header_cap: nil, end_caps: true, underline_header: false)
          table_options = { 
            cap: cap,
            header_cap: header_cap || cap,
            end_caps: end_caps,
            underline_header: underline_header, 
          }
          table_context = {}

          converter.register(:table, Table.new(table_context, table_options))
          converter.register(:tr, Tr.new(table_context, table_options))
          converter.register(:td, Td.new(table_context, table_options))
          converter.register(:th, Th.new(table_context, table_options))
          converter
        end
        module_function :register

        class TableBase < ReverseMarkdown::Converters::Base
          def initialize(table_context, options)
            @table_context = table_context
            @options = options
          end

          def table_did_begin
            super
            @table_context[:next_row_spans] = {}
            @table_context[:inserted_col_spans] = 0
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
              
              if @options[:underline_header]
                # Now github requires an underline in the form of -|-|- matching
                # the header columns.
                content << "-" unless @options[:end_caps]
                content << row_content[0].scan(/#{Regexp.escape(@options[:cap])}/).join("-") 
                content << "-" unless @options[:end_caps]
                content << "\n"
              end

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
            if @table_context[:next_row_spans].any?
              tds = node.element_children

              @table_context[:next_row_spans].each do |td_index, rs|
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

            @table_context[:next_row_spans] = next_row_spans
            @table_context[:inserted_col_spans] = 0

            content = treat_elements(node).strip
            content = "#{content}\n"

            content
          end
        end

        class Td < TableBase
          def convert(node, index)
            content = cleanup_table_cell(treat_children(node))

            content = if @options[:end_caps]
              "#{first_col?(node) ? @options[:cap] : ''}#{content}#{@options[:cap]}"
            else
              "#{first_col?(node) ? '' : @options[:cap]}#{content}"
            end

            # For each spanned column add a column
            colspan = node['colspan'].to_i
            if colspan > 1
              (colspan - 1).times do
                content << "#{COLSPAN_CELL}#{@options[:cap]}"
              end
            end

            # For each spanned row put the information in a variable to be used by
            # the next row
            rowspan = node['rowspan'].to_i
            if rowspan > 1
              iindex = index + @table_context[:inserted_col_spans]
              @table_context[:next_row_spans][iindex] = rowspan

              if colspan > 1
                (colspan - 1).times do |n|
                  @table_context[:next_row_spans][iindex + n + 1] = rowspan
                end
              end
            end

            # Keep track of the number of inserted cells so that we can adjust the
            # rowspan index (above) on the next cell with a rowspan
            @table_context[:inserted_col_spans] += (colspan - 1) if colspan > 1

            content
          end
        end

        class Th < TableBase
          def convert(node, index)
            content = cleanup_table_cell(treat_children(node))

            if @options[:end_caps]
              "#{first_col?(node) ? @options[:header_cap] : ''}#{content}#{@options[:header_cap]}"
            else
              "#{first_col?(node) ? '' : @options[:header_cap]}#{content}"
            end
          end
        end
      end
    end
  end
end

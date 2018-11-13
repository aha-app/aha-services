require "reverse_markdown"

module AhaServices
  class JiraWikiConverter

    def convert_html_from_aha(html)
      preprocess html
      wiki = converter.convert(html)
      postprocess wiki
    end

    def preprocess(html)
      # replace special entities.
      html.gsub!(/&(mdash|#8212);/, '---')
      html.gsub!(/&(ndash|#8211);/, '--')
      # replace non-breaking spaces
      html.gsub!(/&(nbsp|#160);/, ' ')
    end

    def postprocess(wiki)
      wiki.strip
    end

    def converter
      ReverseMarkdown.new(unknown_tags: :bypass) do |c|
        c.register(:hr, Hr.new)
        c.register(:li, Li.new)
        c.register(:a, A.new)
        c.register(:img, Img.new)
        c.register(:pre, Pre.new)
        c.register(:code, Code.new)
        c.register(:blockquote, Blockquote.new)
        c.register(:font, Font.new)
        c.register(:tr, Tr.new)
        c.register(:td, Td.new)
        c.register(:th, Th.new)

        register_mark(c, [:strong, :b], "*")
        register_mark(c, [:em, :i], "_")
        register_mark(c, [:del, :strike, :s], "-")
        register_mark(c, [:u, :ins], "+")
        register_mark(c, [:cite], "??")
        register_mark(c, [:sup], "^")
        register_mark(c, [:sub], "~")

        6.times do |n|
          c.register(:"h#{n + 1}", H.new(n + 1))
        end
      end
    end

    class Mark < ReverseMarkdown::Converters::Base
      def initialize(tags, surround_with)
        @tags = tags
        @surround_with = surround_with
        super()
      end

      def convert(node, index)
        content = treat_children(node)
        if content.strip.empty? || already_marked?(node)
          content
        else
          # Jira cannot handle the marks being against whitespace like * bold *
          # so this moves the whitespace out of the mark.
          pre_content = ""
          post_content = ""

          if content =~ /^\s+/
            pre_content = " "
            content = content.lstrip
          end

          if content =~ /\s+\z/
            post_content = " "
            content = content.rstrip
          end

          [pre_content, @surround_with, content, @surround_with, post_content].join
        end
      end

      def already_marked?(node)
        @tags.any? do |name|
          node.ancestors(name).any?
        end
      end
    end

    def register_mark(converter, tags, surround_with)
      mark_instance = Mark.new(tags, surround_with)
      converter.register(tags, mark_instance)
    end

    class Code < ReverseMarkdown::Converters::Base
      def convert(node, index)
        "{{#{node.text}}}"
      end
    end

    class Pre < ReverseMarkdown::Converters::Base
      def convert(node, index)
        "\n{noformat}\n#{node.text.strip}\n{noformat}\n"
      end
    end

    class Hr < ReverseMarkdown::Converters::Base
      def convert(node, index)
        "\n----\n"
      end
    end

    class Li < ReverseMarkdown::Converters::Base
      def convert(node, _index)
        content     = treat_children(node)
        prefix      = prefix_for(node)
        indentation = "  "

        content.strip.lines.each_with_index.map do |line, index|
          line = line.sub(/\n*/m, "").rstrip

          if index == 0
            "#{prefix}#{line}\n"
          elsif line =~ /^\s*$/
          elsif line =~ /^[*#]/
            indentation = ""
            "#{line}\n"
          else
            "#{indentation}#{line}\n"
          end
        end.join
      end

      def prefix_for_checklist(node)
        if node["class"].to_s.include?("unchecked")
          "(x)"
        else
          "(/)"
        end
      end

      def prefix_for(node)
        prefix = ""
        pnode = node.respond_to?(:parent) ? node.parent : nil
        while pnode
          next_prefix = if pnode == node.parent && pnode["class"].to_s.include?("checklist")
            prefix_for_checklist(node)
          elsif pnode.name == "ol"
            "#"
          elsif pnode.name == "ul"
            "*"
          end
          prefix = next_prefix + prefix if next_prefix
          pnode = pnode.respond_to?(:parent) ? pnode.parent : nil
        end
        prefix + " "
      end

      def indentation_for(node)
        ""
      end
    end

    module Table
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
    end

    class Tr < ReverseMarkdown::Converters::Tr
      include Table

      def convert(node, index)
        content = treat_children(node).strip
        "#{content}\n"
      end
    end

    class Td < ReverseMarkdown::Converters::Td
      include Table

      def convert(node, index)
        content = cleanup_table_cell(treat_children(node))
        "#{first_col?(node) ? '|' : ''}#{content}|"
      end
    end

    class Th < ReverseMarkdown::Converters::Td
      include Table

      def convert(node, index)
        content = cleanup_table_cell(treat_children(node))
        "#{first_col?(node) ? '||' : ''}#{content}||"
      end
    end

    class A < ReverseMarkdown::Converters::Base
      def convert(node, index)
        href = node['href']
        name = node['name']

        if name.present? && href.blank?
          convert_anchor(node)
        elsif href.to_s.start_with?("#")
          convert_anchor_link(node)
        else
          convert_link(node)
        end
      end

      def convert_anchor(node)
        "{anchor:#{node['name']}}"
      end

      def convert_anchor_link(node)
        href = node['href']
        "[#{href}]"
      end

      def convert_link(node)
        content = treat_children(node)
        href = node['href']
        if href.blank?
          content
        elsif content.strip.blank? || content.strip == href
          "[#{href}]"
        else
          "[#{content}|#{href}]"
        end
      end
    end

    class Blockquote < ReverseMarkdown::Converters::Base
      def convert(node, index)
        content = treat_children(node)
        "\n{quote}\n#{content.strip}\n{quote}\n"
      end
    end

    class H < ReverseMarkdown::Converters::Base
      def initialize(level)
        @level = level
        super()
      end

      def convert(node, index)
        prefix = "h#{@level}."
        ["\n", prefix, ' ', treat_children(node), "\n"].join
      end
    end

    class Img < ReverseMarkdown::Converters::Base
      EMOTICONS = {
        smile: ":)",
        sad: ":(",
        tongue: ":P",
        biggrin: ":D",
        wink: ";)",
        thumbs_up: "(y)",
        thumbs_down: "(n)",
        information: "(i)",
        check: "(/)",
        error: "(x)",
        warning: "(!)",
        add: "(+)",
        forbidden: "(-)",
        help_16: "(?)",
        lightbulb_on: "(on)",
        lightbulb: "(off)",
        star_yellow: "(*)",
        star_red: "(*r)",
        star_green: "(*g)",
        star_blue: "(*b)",
      }.freeze

      def convert(node, index)
        if node['src'].include?('emoticons/')
          did_convert = convert_emoticon(node)
          return did_convert if did_convert.present?
        end

        attrs = img_attrs(node)
        " !" + node['src'] + (attrs.any? ? "|#{attrs.join(', ')}" : "") + "!"
      end

      def img_attrs(node)
        node.attributes.slice("width", "height", "align", "valign", "alt")
          .values
          .select { |attr| attr.value.present? }
          .map { |attr| [attr.name, attr.value].join("=") }
      end

      def convert_emoticon(node)
        emoticon = node['src'].scan(/\/emoticons\/(.+)\.(?:png|gif)/).flatten.first
        EMOTICONS[emoticon.to_sym]
      end
    end

    class Font < ReverseMarkdown::Converters::Base
      def convert(node, index)
        content = treat_children(node)

        if (color = node['color']).present?
          "{color:#{color}}#{content}{color}"
        else
          content
        end
      end
    end
  end
end

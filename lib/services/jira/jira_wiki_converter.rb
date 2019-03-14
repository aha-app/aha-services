require "reverse_markdown"

module AhaServices
  class JiraWikiConverter
    def convert_html_from_aha(html)
      return html if html.blank?
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
        c.register(:p, P.new)
        c.register(:hr, Hr.new)
        c.register(:br, Br.new)
        c.register(:li, Li.new)
        c.register(:a, A.new)
        c.register(:img, Img.new)
        c.register(:pre, Pre.new)
        c.register(:code, Code.new)
        c.register(:blockquote, Blockquote.new)
        c.register(:span, Span.new)
        c.register(:font, Font.new)

        AhaServices::Services::Common::MarkdownTableConverter.register(c, header_cap: "||")

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
      
    class AnchorBase < ReverseMarkdown::Converters::Base
      def treat_children(node)
        children = ''
        if (anchor = node['data-anchor']).present?
          children << "{anchor:#{anchor}}"
        end
        children + super(node)
      end
    end
    
    class P < AnchorBase
      def convert(node, index)
        "\n\n" << treat_children(node).strip << "\n\n"
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
        if node.children.length == 1 && node.children.first.name == 'code'
          node = node.children.first
        end

        content = treat_children(node)
        "\n{noformat}\n#{content}\n{noformat}\n"
      end
    end

    class Hr < ReverseMarkdown::Converters::Base
      def convert(node, index)
        "\n----\n"
      end
    end

    class Br < ReverseMarkdown::Converters::Base
      def convert(node, index)
        "\n"
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
        if node.respond_to?(:parent) && node.parent["class"].to_s.include?("checklist")
          return prefix_for_checklist(node) + " "
        end

        prefix = ""
        pnode = node.respond_to?(:parent) ? node.parent : nil
        while pnode
          if pnode.name == "ol"
            prefix = "#" + prefix
          elsif pnode.name == "ul"
            prefix = "*" + prefix
          end
          pnode = pnode.respond_to?(:parent) ? pnode.parent : nil
        end
        prefix + " "
      end

      def indentation_for(node)
        ""
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

    class H < AnchorBase
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
        return "" unless node['src']
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
        EMOTICONS[emoticon.to_sym] if emoticon
      end
    end

    class Span < ReverseMarkdown::Converters::Base
      def convert(node, index)
        content = treat_children(node)
        style = node.attributes["style"]&.value
        if (color = style&.match(/([^-]|\A)color:([^;]{3,})/))
          converted = AhaServices::Services::Common::ColorConverter.aha_color_to_jira(color[2])
          "{color:#{converted}}#{content}{color}"
        else
          content
        end
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

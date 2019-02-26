require "spec_helper"
require "services/jira/jira_wiki_converter"

RSpec.describe AhaServices::JiraWikiConverter do
  let(:converter) { described_class.new }

  subject(:output) { converter.convert_html_from_aha(input).strip }

  context "marks" do
    let(:input) do
      <<~HTML
        <p>
          normal <b>bold</b> <strong>strong</strong>
          <b>already <strong>bold</strong></b>
          normal <i>italic</i> <em>emphasised</em>
          <em>already <i>emphasised</i></em>
          normal <strong><em>strong emphasised</em></strong>
          normal <del>deleted</del> <strike>striked</strike> <s>striked 2</s>
          <del>already <strike>del<s>eted</s></strike></del>
          normal <u>underline</u> <ins>underline</ins>
          <u>already <ins>underlined</ins></u>
          normal <cite>citation</cite>
          <cite>already <cite>citated</cite></cite>
          normal <sub>subscript</sub>
          <sub>already <sub>subscripted</sub></sub>
          normal <sup>superscript</sup>
          <sup>already <sup>super</sup></sup>
        </p>
      HTML
    end

    it { is_expected.to include("normal *bold* *strong*") }
    it { is_expected.to include("*already bold*") }
    it { is_expected.to include("normal _italic_ _emphasised_") }
    it { is_expected.to include("_already emphasised_") }
    it { is_expected.to include("normal *_strong emphasised_*") }
    it { is_expected.to include("normal -deleted- -striked- -striked 2-") }
    it { is_expected.to include("-already deleted-") }
    it { is_expected.to include("normal +underline+ +underline+") }
    it { is_expected.to include("+already underlined+") }
    it { is_expected.to include("normal ??citation??") }
    it { is_expected.to include("??already citated??") }
    it { is_expected.to include("normal ~subscript~") }
    it { is_expected.to include("~already subscripted~") }
    it { is_expected.to include("normal ^superscript^") }
    it { is_expected.to include("^already super^") }

    context "marks and whitespace" do
      let(:input) do
        <<~HTML
          <p>
            <strong>bold </strong><em>italic&nbsp;</em><u>underline </u>
          </p>
        HTML
      end

      it "normalizes whitespacing in mark tags" do
        is_expected.to eq(<<~WIKI.strip)
          *bold* _italic_ +underline+
        WIKI
      end
    end
  end

  context "tables" do
    let(:input) do
      <<~HTML
        <table>
          <tbody>
            <tr>
              <th>
                <p>header
                  1</p>
              </th>
              <th>
                <p>header 2</p>
              </th>
              <th>
                <p>header
                  3</p>
              </th>
            </tr>
            <tr>
              <td>
                <p>1.1</p>
              </td>
              <td>
              </td>
              <td>
                <p>1.3</p>
              </td>
            </tr>
            <tr>
              <td>
                <p>2.1</p>
              </td>
              <td>
                <p><pre>2.2</pre></p>
              </td>
              <td>
                <p>2.3</p>
              </td>
            </tr>
          </tbody>
        </table>
      HTML
    end

    it "makes a wiki table" do
      expect(output).to eq(<<~WIKI.strip)
        ||header 1||header 2||header 3||
        |1.1| |1.3|
        |2.1|{noformat}
        2.2
        {noformat}|2.3|
      WIKI
    end
  end

  context "lists" do
    let(:input) do
      <<~HTML
        <ul>
          <li>
            <p>one</p>
            <ul>
              <li>
                <p>one.one</p>
              </li>
            </ul>
          </li>
          <li>
            <p>two</p>
            <ul>
              <li>
                <p>two.two</p>
              </li>
            </ul>
          </li>
          <li>
            <p>three</p>
            <ul>
              <li>
                <p>three.three</p>
              </li>
            </ul>
          </li>
        </ul>
        <ol>
          <li>
            <p>one</p>
            <ol>
              <li>
                <p>one.one</p>
              </li>
              <li>
                <p>
                  one.two<br/>
                  <ul>
                    <li>one.two.one</li>
                    <li>one.two.two</li>
                  </ul>
                </p>
              </li>
            </ol>
          </li>
          <li>
            <p><strong>two</strong></p>
          </li>
          <li>
            <p>three</p>
          </li>
          <li>
            <p>four</p>
          </li>
        </ol>
      HTML
    end

    it "makes wiki lists" do
      expect(output).to eq(<<~WIKI.strip)
        * one
        ** one.one
        * two
        ** two.two
        * three
        ** three.three

        # one
        ## one.one
        ## one.two
        ##* one.two.one
        ##* one.two.two
        # *two*
        # three
        # four
      WIKI
    end
  end

  describe "checks" do
    let(:input) do
      <<~HTML
        <ul class="checklist">
        <li class="checklist--unchecked">check 1</li>
        <li>check 2</li>
        </ul>
      HTML
    end

    it "becomes check list items" do
      expect(output).to eq(<<~WIKI.strip)
        (x) check 1
        (/) check 2
      WIKI
    end
  end

  describe "links" do
    let(:input) do
      <<~HTML
        <a href="https://example.net">#{content}</a>
      HTML
    end

    context "label is same as href" do
      let(:content) { "https://example.net" }

      it { is_expected.to eq "[https://example.net]" }
    end

    context "label is different" do
      let(:content) { "Link to example" }

      it { is_expected.to eq "[Link to example|https://example.net]" }
    end
  end

  describe "anchors" do
    let(:input) do
      <<~HTML
        <p>
          <a name="namedAnchor"></a> anchored
        </p>
        <p>
          <a href="#namedAnchor">link to anchor</a>
        </p>
      HTML
    end

    it "makes an anchor" do
      is_expected.to eq(<<~WIKI.strip)
        {anchor:namedAnchor} anchored

        [#namedAnchor]
      WIKI
    end
  end

  describe "inline code" do
    let(:input) do
      <<~HTML
        <p>Some <code>inline</code> code example</p>
      HTML
    end

    it "makes wiki inline code" do
      expect(output).to eq(<<~WIKI.strip)
        Some {{inline}} code example
      WIKI
    end
  end

  describe "preformatted" do
    let(:input) do
      <<~HTML
        <body>
          <p>Plain paragraph</p>
          <pre>
            Preformatted paragraph
          </pre>
          <pre>
            <code>
              Preformatted code paragraph
            </code>
          </pre>
        </body>
      HTML
    end

    it "makes wiki {noformat} blocks" do
      expect(output).to eq(<<~WIKI.strip)
        Plain paragraph

        {noformat}
         Preformatted paragraph 
        {noformat}

        {noformat}
        {{
              Preformatted code paragraph
            }}
        {noformat}
      WIKI
    end
  end

  describe "blockquote" do
    let(:input) { "<blockquote>A quote</blockquote>" }

    it { is_expected.to eq("{quote}\nA quote\n{quote}") }
  end

  describe "Headings" do
    let(:input) do
      <<~HTML
        <h1>Heading 1</h1>
        <h2>Heading 2</h2>
        <h3>Heading 3</h3>
        <h4>Heading 4</h4>
        <h5>Heading 5</h5>
        <h6>Heading 6</h6>
      HTML
    end

    it "makes wiki headings" do
      expect(output).to eq(<<~WIKI.strip)
        h1. Heading 1

        h2. Heading 2

        h3. Heading 3

        h4. Heading 4

        h5. Heading 5

        h6. Heading 6
      WIKI
    end
  end

  describe "images" do
    let(:input) do
      <<~HTML
        <p><img src="https://example.net/image.png" width="100" height="200"></p>
      HTML
    end

    it { is_expected.to eq "!https://example.net/image.png|width=100, height=200!" }
    
    context "emoji" do
      let(:images) do
        {
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
        }
      end

      let(:input) do
        "<p>" +
          images.map do |name, _|
            %(<img src="https://example.net/images/icons/emoticons/#{name}.png" class="emoticon">)
          end.join(" ") + "</p>"
      end

      it "convert emoji from jira" do
        expect(output).to_not match(/!.+png/)
        images.each do |name, emoji|
          expect(output).to_not include(name.to_s)
          expect(output).to include(emoji)
        end
      end
    end
  end

  describe "span color" do
    let(:input) do
      <<~HTML
        <p><span style="color:red">look ma, red text!</span></p>
      HTML
    end

    it do
      is_expected.to eq(<<~WIKI.strip)
        {color:red}look ma, red text!{color}
      WIKI
    end

    context "retain breaks" do
      let(:input) do
        <<~HTML
          <p><span style="color:red"><br>look ma, red text!</span></p>
        HTML
      end

      it do
        is_expected.to eq(<<~WIKI.strip)
          {color:red}
          look ma, red text!{color}
        WIKI
      end
    end
  end

  describe "font color" do
    let(:input) do
      <<~HTML
        <p><font color="red">look ma, red text!</font></p>
      HTML
    end

    it do
      is_expected.to eq(<<~WIKI.strip)
        {color:red}look ma, red text!{color}
      WIKI
    end

    context "retain breaks" do
      let(:input) do
        <<~HTML
          <p><font color="red"><br>look ma, red text!</font></p>
        HTML
      end

      it do
        is_expected.to eq(<<~WIKI.strip)
          {color:red}
          look ma, red text!{color}
        WIKI
      end
    end
  end

  describe "<hr>" do
    let(:input) do
      <<~HTML
        <p>text</p>
        <hr/>
        <p>separated</p>
        <hr>
        <p>by hrs</p>
      HTML
    end

    it do
      is_expected.to eq(<<~WIKI.strip)
        text

        ----

        separated

        ----

        by hrs
      WIKI
    end
  end

  describe "special characters" do
    let(:input) do
      <<~HTML
        <p>nb space 1: &nbsp; there</p>
        <p>nb space 2: &#160; there</p>
        <p>mdash 1: &mdash; there</p>
        <p>mdash 2: &#8212; there</p>
        <p>ndash 1: &ndash; there</p>
        <p>ndash 2: &#8211; there</p>
      HTML
    end

    it { is_expected.to include "nb space 1: there" }
    it { is_expected.to include "nb space 2: there" }
    it { is_expected.to include "mdash 1: --- there" }
    it { is_expected.to include "mdash 2: --- there" }
    it { is_expected.to include "ndash 1: -- there" }
    it { is_expected.to include "ndash 2: -- there" }
  end

  describe "images within a link" do
    let(:imagetarget) { "https://example.com/image.jpg" }
    let(:link) { "https://example.com/index.html" }
    let(:input) do
      <<~HTML
        <p>
          <a href="#{link}" target="_blank">
            <img src="#{imagetarget}"
            alt=""
            width="300" />
          </a>
        </p>
      HTML
    end

    it { is_expected.to eq("[!#{imagetarget}|width=300!|#{link}]") }
  end
end

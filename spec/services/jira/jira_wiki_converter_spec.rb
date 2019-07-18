require "spec_helper"

RSpec.describe AhaServices::JiraWikiConverter do
  let(:converter) { described_class.new }

  subject(:output) { converter.convert_html_from_aha(input)&.strip }

  context "nil input" do
    let(:input) { nil }

    it { is_expected.to eq(nil) }
  end

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
    context "normal table" do
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

    context "table with rowspan and colspan" do
      let(:input) do
        <<~HTML
          <table>
            <tbody>
              <tr><td>One</td><td>Two</td><td>Three</td></tr>
              <tr>
                <td colspan="2">One&Two</td>
                <td>Three</td>
              </tr>
              <tr>
                <td rowspan="2">One&One</td>
                <td>Two</td>
                <td>Three</td>
              </tr>
              <tr>
                <td>Two</td>
                <td>Three</td>
              </tr>
              <tr>
                <td>One</td>
                <td rowspan="3">Two&Two&Two</td>
                <td>Three</td>
              </tr>
              <tr>
                <td>One</td>
                <td>Three</td>
              </tr>
              <tr>
                <td>One</td>
                <td>Three</td>
              </tr>
            </tbody>
          </table>
        HTML
      end

      it "Outputs a correct table" do
        expect(output).to eq(<<~WIKI.strip)
          |One|Two|Three|
          |One&Two|\uFEFF|Three|
          |One&One|Two|Three|
          |\uFEFF\uFEFF|Two|Three|
          |One|Two&Two&Two|Three|
          |One|\uFEFF\uFEFF|Three|
          |One|\uFEFF\uFEFF|Three|
        WIKI
      end
    end

    context "rowspan and colspan on td top left" do
      let(:input) do
        <<~HTML
          <table>
            <tr>
              <td colspan="3" rowspan="2">Top left</td>
              <td>Top right</td>
            </tr>
            <tr>
              <td>Center right</td>
            </tr>
            <tr>
              <td>Bottom left</td>
              <td>Bottom</td>
              <td>Bottom</td>
              <td>Bottom right</td>
            </tr>
          </table>
        HTML
      end

      it "Outputs a correct table" do
        expect(output).to eq(<<~WIKI.strip)
          |Top left|\uFEFF|\uFEFF|Top right|
          |\uFEFF\uFEFF|\uFEFF\uFEFF|\uFEFF\uFEFF|Center right|
          |Bottom left|Bottom|Bottom|Bottom right|
        WIKI
      end
    end

    context "rowspan and colspan on td bottom right" do
      let(:input) do
        <<~HTML
          <table>
            <tr>
              <td>Top left</td>
              <td>Top</td>
              <td>Top</td>
              <td>Top right</td>
            </tr>
            <tr>
              <td>Center left</td>
              <td colspan="3" rowspan="2">Bottom right</td>
            </tr>
            <tr>
              <td>Bottom left</td>
            </tr>
          </table>
        HTML
      end

      it "Outputs a correct table" do
        expect(output).to eq(<<~WIKI.strip)
          |Top left|Top|Top|Top right|
          |Center left|Bottom right|\uFEFF|\uFEFF|
          |Bottom left|\uFEFF\uFEFF|\uFEFF\uFEFF|\uFEFF\uFEFF|
        WIKI
      end
    end

    context "rowspan and colspan centered" do
      let(:input) do
        <<~HTML
          <table>
            <tr>
              <td>Top left</td>
              <td>Top</td>
              <td>Top</td>
              <td>Top right</td>
            </tr>
            <tr>
              <td>Center left</td>
              <td colspan="2" rowspan="2">Center</td>
              <td>Center right</td>
            </tr>
            <tr>
              <td>Center left</td>
              <td>Center right</td>
            </tr>
            <tr>
              <td>Bottom left</td>
              <td>Bottom</td>
              <td>Bottom</td>
              <td>Bottom right</td>
            </tr>
          </table>
        HTML
      end

      it "Outputs a correct table" do
        expect(output).to eq(<<~WIKI.strip)
          |Top left|Top|Top|Top right|
          |Center left|Center|\uFEFF|Center right|
          |Center left|\uFEFF\uFEFF|\uFEFF\uFEFF|Center right|
          |Bottom left|Bottom|Bottom|Bottom right|
        WIKI
      end
    end

    context "rowspan and colspan left center right" do
      let(:input) do
        <<~HTML
          <table>
            <tr>
              <td rowspan="3">Left</td>
              <td colspan="2">Top</td>
              <td rowspan="3">Right</td>
            </tr>
            <tr>
              <td>1</td>
              <td>2</td>
            </tr>
            <tr>
              <td>3</td>
              <td>4</td>
            </tr>
          </table>
        HTML
      end

      it "Outputs a correct table" do
        expect(output).to eq(<<~WIKI.strip)
          |Left|Top|\uFEFF|Right|
          |\uFEFF\uFEFF|1|2|\uFEFF\uFEFF|
          |\uFEFF\uFEFF|3|4|\uFEFF\uFEFF|
        WIKI
      end
    end

    context "colgroups" do
      let(:input) do
        <<~HTML
          <p></p>
          <div class="table-wrapper" style="width:567px;max-width:100%">
            <table>
              <colgroup>
                <col style="width:38%"/>
                <col style="width:62%"/>
              </colgroup>
              <tbody>
                <tr>
                  <td style="width:38%">
                    <p>Col 1</p>
                  </td>
                  <td style="width:62%">
                    <p>Col 2</p>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        HTML
      end

      it "makes some output" do
        expect(output).to eq(<<~WIKI.strip)
          |Col 1|Col 2|
        WIKI
      end
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
          <li class="checkbox">
            <span>check 2</span>
            <ul class="checklist">
              <li class="checkbox checklist--checked">check 2.1</li>
            </ul>
          </li>
          <li class="checklist--checked">check 3</li>
        </ul>
      HTML
    end

    it "becomes check list items" do
      expect(output).to eq(<<~WIKI.strip)
        (x) check 1
        (/) check 2
          (/) check 2.1
        (/) check 3
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
          <pre>Preformatted paragraph</pre>
          <pre><code>Preformatted code paragraph</code></pre>
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
        Preformatted code paragraph
        {noformat}
      WIKI
    end

    context "containing brs" do
      let(:input) do
        <<~HTML
          <body>
            <pre>Line 1<br>Line 2</pre>
            <pre><code>Line 1a<br>Line 2a</code></pre>
          </body>
        HTML
      end

      it { is_expected.to eq("{noformat}\nLine 1\nLine 2\n{noformat}\n\n{noformat}\nLine 1a\nLine 2a\n{noformat}") }
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

    context "no src attrbiute" do

      let(:input) do
        <<~HTML
          <p><img  width="100" height="200"></p>
        HTML
      end

      it { is_expected.to eq "" }
    end

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

      context "bad input" do

        let(:input) do
          "<p>" +
            images.map do |name, _|
              %(<img src="https://example.net/images/icons/emoticons/#{name}.oft" class="emoticon">)
            end.join(" ") + "</p>"
        end

        it "convert emoji from jira" do
          images.each do |name, emoji|
            expect(output).to include(name.to_s)
            expect(output).to_not include(emoji)
          end
        end

      end
    end
  end

  describe "span color" do
    let(:input) do
      <<~HTML
        <p>now the <span style="background-color:#9973CF; color:#0073CF; becker:left">blue</span> pants are <span style="becker: left;color:#D50000">red</span></p>
      HTML
    end

    it do
      is_expected.to eq(<<~WIKI.strip)
        now the {color:#59afe1}blue{color} pants are {color:#d04437}red{color}
      WIKI
    end

    context "retain breaks" do
      let(:input) do
        <<~HTML
          <p>now the <span style="color:#0073CF">blue</span> pants<br> are <span style="color:#D50000">red</span></p>
        HTML
      end

      it do
        is_expected.to eq(<<~WIKI.strip)
          now the {color:#59afe1}blue{color} pants
           are {color:#d04437}red{color}
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

  describe "<br>" do
    let(:input) do
      <<~HTML
        <p>
          text on<br/>two lines
        </p>
      HTML
    end

    it do
      is_expected.to eq("text on\ntwo lines")
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

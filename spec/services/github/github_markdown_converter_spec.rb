require "spec_helper"

RSpec.describe GithubMarkdownConverter do
  let(:converter) do
    described_class.new
  end

  let(:output) do
    converter.convert_html_from_aha(input).strip
  end

  describe "tables" do
    context "1 row" do
      let(:input) do
        <<~HTML
          <table><tr><td>h1</td><td>h2</td></tr></table>
        HTML
      end

      it do
        expect(output).to eq(<<~MK.strip)
          h1|h2
          -|-
        MK
      end
    end

    context "n rows" do
      let(:input) do
        <<~HTML
          <table>
            <tr><td>h1</td><td>h2</td></tr>
            <tr><td>c1</td><td>c2</td></tr>
            <tr><td>c3</td><td>c4</td></tr>
          </table>
        HTML
      end

      it do
        expect(output).to eq(<<~MK.strip)
          h1|h2
          -|-
          c1|c2
          c3|c4
        MK
      end
    end

    context "thead and tbody" do
      let(:input) do
        <<~HTML
          <table>
            <thead>
              <tr><th>h1</th><th>h2</th></tr>
            </thead>
            <tbody>
              <tr><td>c1</td><td>c2</td></tr>
              <tr><td>c3</td><td>c4</td></tr>
            </tbody>
          </table>
        HTML
      end

      it do
        expect(output).to eq(<<~MK.strip)
          h1|h2
          -|-
          c1|c2
          c3|c4
        MK
      end
    end
  end
end

require "spec_helper"

describe Helpers do
  let(:instance) { Class.new { include Helpers }.new }

  describe "#markdown_to_html" do
    subject { instance.markdown_to_html(md) }

    context "converts a string to a paragraph" do
      let(:md) { "some text" }

      it { is_expected.to eq("<p>some text</p>") }
    end

    context "double newlines start a new paragraph" do
      let(:md) { "line 1\n\nline 2\n\nline 3" }

      it { is_expected.to eq("<p>line 1</p><p>line 2</p><p>line 3</p>") }
    end

    context "single newlines are converted to <br>" do
      let(:md) { "this text has\na newline\nand another" }

      it { is_expected.to eq("<p>this text has<br>a newline<br>and another</p>") }
    end
  end
end

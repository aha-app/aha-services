require "spec_helper"

describe AhaServices::GoogleHangoutsChat do
  let(:service_with_updated_feature) do
    payload = {
      "event"=>"audit",
     "audit"=>
      {
        "id"=>"6543581008138760991",
       "audit_action"=>"update",
       "created_at"=>"2018-04-12T15:16:17.922Z",
       "interesting"=>true,
       "user"=>{"id"=>"6514078897796815681", "name"=>"Product Manager", "email"=>"pm@example.com", "created_at"=>"2018-01-23T03:13:02.585Z", "updated_at"=>"2018-04-10T14:36:51.715Z"},
       "auditable_type"=>"feature",
       "auditable_id"=>"6514078362261846610",
       "description"=>"updated feature DEMO-28 Language options",
       "auditable_url"=>"http://reallybigaha.lvh.me:3000/features/DEMO-28",
       "changes"=>[{"field_name"=>"Workflow status", "value"=>"Under consideration &rarr; Ready to develop"}]
      }
    }
    described_class.new( {}, payload )
  end

  let(:service_with_voted_idea) do
    payload = {
      "event"=>"audit",
      "audit"=>
      {
        "id"=>"6543586303049439552",
        "audit_action"=>"create",
        "created_at"=>"2018-04-12T15:36:50.739Z",
        "interesting"=>true,
        "user"=>{"id"=>"6514078897796815681", "name"=>"Product Manager", "email"=>"pm@example.com", "created_at"=>"2018-01-23T03:13:02.585Z", "updated_at"=>"2018-04-12T15:36:50.763Z"},
        "auditable_type"=>"ideas/idea_endorsement",
        "auditable_id"=>"6543586302962967491",
        "description"=>"voted for idea DEMO-I-15 Alert me to overtraining",
        "auditable_url"=>"http://reallybigaha.lvh.me:3000/ideas/ideas/DEMO-I-15",
        "changes"=>[]
      }
    }
    described_class.new( {}, payload )
  end

  def get_card_sections(message)
    message[:cards].first[:sections]
  end

  context "#receive_audit" do
    it "sets the right number of sections when changes are present" do
      expect(service_with_updated_feature).to receive(:send_message) do |message|
        expect(get_card_sections(message).length).to eq(3)
      end
      service_with_updated_feature.receive_audit
    end

    it "sets the right number of sections when changes are present" do
      expect(service_with_voted_idea).to receive(:send_message) do |message|
        expect(get_card_sections(message).length).to eq(2)
      end
      service_with_voted_idea.receive_audit
    end
  end

  context("#html_change_colors") do
    subject { described_class.new }
    it "replaces inserted and deleted <span> elements with <font> elements" do
      edited_description = 'This is might <span class="deleted">not</span> be edited <span class="inserted">by a user</span>'
      expect(subject.send(:html_change_colors, edited_description)).not_to include('<span')
      expect(subject.send(:html_change_colors, edited_description)).to include('<font')
    end
  end

end

require 'spec_helper'

RSpec.describe JiraResource do
  let(:resource) { described_class.new(service) }
  let(:service) { AhaServices::Jira.new(service_options) }

  context 'jwt handling' do
    let(:api_url) { 'https://test.host/api/v2' }
    let(:service_options) do
      {
        user_id: user_id,
        atlassian_account_id: atlassian_account_id,
        shared_secret: shared_secret,
        server_url: 'https://test.host'
      }
    end
    let(:user_id) {}
    let(:atlassian_account_id) {}
    let(:shared_secret) { 'shhhhh' }
    let(:request_regex) { /#{api_url}(\?jwt=.*)?/ }

    before { stub_request(:get, request_regex).to_return(status: 200) }

    def claims
      jwt = nil
      expect(
        a_request(:get, request_regex)
          .with { |req| jwt = req.uri.query_values['jwt'] }
      ).to have_been_made
      JWT.decode(jwt, shared_secret, true).first
    end

    # This is where the action happens. It's not in a subject block because we
    # don't care about the result
    before { resource.http_get(api_url) }

    shared_examples_for 'a Jira request with JWT' do
      it 'has no user_id param' do
        expect(a_request(:get, api_url)
          .with(query: hash_including(user_id: user_id))).to_not have_been_made
      end

      it 'has a jwt param' do
        expect(a_request(:get, api_url)
          .with(query: hash_including(jwt: anything))).to have_been_made
      end

      it 'sets the iss claim to aha' do
        expect(claims['iss']).to eq('io.aha.connect')
      end

      it 'sets the iat claim' do
        expect(claims['iat'].to_s).to match(/\d+/)
      end

      it 'sets the exp claim to 5 minutes from now' do
        expect(claims['exp']).to be >= Time.now.utc.to_i
      end

      it 'sets the qsh claim' do
        expect(claims['qsh']).to be_present
      end
    end

    context 'when service config contains a user_id' do
      let(:user_id) { 'user-id-abc123' }

      it_behaves_like 'a Jira request with JWT'

      it 'sets the sub claim with the user key' do
        expect(claims['sub']).to eq("urn:atlassian:connect:userkey:#{user_id}")
      end
    end

    context 'when service config has an atlassian_account_id' do
      let(:atlassian_account_id) { 'account-id-abc123' }

      it_behaves_like 'a Jira request with JWT'

      it 'sets the sub claim with the account ID' do
        expect(claims['sub'])
          .to eq("urn:atlassian:connect:useraccountid:#{atlassian_account_id}")
      end
    end

    context 'when service config has a blank user_id' do
      let(:user_id) { '' }

      it_behaves_like 'a Jira request with JWT'

      it 'does not set the sub claim' do
        expect(claims).to_not have_key('sub')
      end
    end

    context 'when service config has no user_id or atlassian_account_id' do
      it 'has no user_id param' do
        expect(
          a_request(:get, api_url)
            .with(query: hash_including(user_id: anything))
        ).to_not have_been_made
      end

      it 'has no jwt param' do
        expect(
          a_request(:get, api_url)
            .with(query: hash_including(jwt: anything))
        ).to_not have_been_made
      end

      it 'has no auth header' do
        expect(
          a_request(:get, api_url)
            .with { |req| req.headers['HTTP_AUTHORIZATION'] =~ /^OAuth / }
        ).to_not have_been_made
      end
    end
  end
end

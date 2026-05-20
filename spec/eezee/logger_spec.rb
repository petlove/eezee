# frozen_string_literal: true

RSpec.describe Eezee::Logger, type: :model do
  describe '.request' do
    subject do
      Eezee::Logger.request(
        FactoryBot.build(
          :request,
          path: nil,
          params: { user: 1 },
          headers: { Token: 'Token 2b173033-45fa-459a-afba-9eea79cb75be' },
          payload: { street: 'Paulista Avenue' }
        ),
        :GET
      )
    end

    after { subject }

    it 'puts request logs' do
      expect(described_class)
      receive(:p)
        .with(
          '{"type":"request","method":"GET","uri":"https://www.linqueta.com?user=1",' \
          '"headers":{"Token":"Token 2b173033-45fa-459a-afba-9eea79cb75be"},' \
          '"payload":{"street":"Paulista Avenue"}}'
        )
        .once
    end
  end

  describe '.filter_headers' do
    it 'masks Authorization header' do
      result = described_class.filter_headers({ 'Authorization' => 'Bearer secret' })
      expect(result).to eq({ 'Authorization' => '[FILTERED]' })
    end

    it 'masks Ocp-Apim-Subscription-Key header' do
      result = described_class.filter_headers({ 'Ocp-Apim-Subscription-Key' => 'abc123' })
      expect(result).to eq({ 'Ocp-Apim-Subscription-Key' => '[FILTERED]' })
    end

    it 'preserves non-sensitive headers' do
      result = described_class.filter_headers({ 'Content-Type' => 'application/json' })
      expect(result).to eq({ 'Content-Type' => 'application/json' })
    end

    it 'is case-insensitive for header names' do
      result = described_class.filter_headers({ 'authorization' => 'Bearer secret' })
      expect(result).to eq({ 'authorization' => '[FILTERED]' })
    end

    it 'returns non-hash input unchanged' do
      expect(described_class.filter_headers(nil)).to be_nil
    end
  end

  describe '.response' do
    subject { Eezee::Logger.response(response) }

    let(:response) { Eezee::Response.new(nil) }

    before do
      allow(response).to receive(:body).and_return(error: 'some error')
      allow(response).to receive(:code).and_return(400)
      allow(response).to receive(:success).and_return(false)
      allow(response).to receive(:timeout?).and_return(false)
    end

    after { subject }

    it 'puts response logs' do
      expect(described_class).to receive(:p)
        .with(
          '{"type":"response","success":false,"timeout":false,"code":400,' \
          '"body":{"error":"some error"}}'
        )
        .once
    end
  end

  describe '.response' do
    subject { Eezee::Logger.error(error) }

    let(:error) { Eezee::ResourceNotFoundError.new(request, response) }
    let(:response) { Eezee::Response.new(nil) }
    let(:request) { build :request }

    before do
      allow(response).to receive(:body).and_return(error: 'some error')
      allow(response).to receive(:code).and_return(400)
      allow(response).to receive(:success).and_return(false)
      allow(response).to receive(:timeout?).and_return(false)
    end

    after { subject }

    it 'puts response logs' do
      expect(described_class)
        .to receive(:p)
        .with(
          '{"type":"error","klass":"Eezee::ResourceNotFoundError",' \
          '"success":false,"timeout":false,"code":400,' \
          '"body":{"error":"some error"}}'
        )
        .once
    end
  end
end

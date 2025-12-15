# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Eezee::TimeoutError, type: :model do
  describe '#log' do
    let(:original) { double('original', response: { status: 400 }, body: { error: 'some error' }, success?: false) }
    let(:response) { Eezee::Response.new(original) }
    let(:error) { described_class.new(response) }

    it do
      expect(Eezee::Logger).to receive(:error).with(error, false)
      error.log
    end

    context 'when single_line_logger is true' do
      subject { error.log }

      after { subject }

      before do
        allow(response).to receive(:single_line_logger).and_return(true)
      end

      it 'logs a single line error message' do
        expect(Eezee::Logger).to receive(:p).with('INFO -- error: Eezee::TimeoutError error: SUCCESS: false TIMEOUT: false CODE: 400 BODY: {}').once
      end
    end
  end
end

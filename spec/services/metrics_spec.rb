require 'rails_helper'

RSpec.describe Metrics do
  describe '.log' do
    it 'requires a block' do
      expect { described_class.log(:arg, 'arg') }.to raise_error(/Block required/)
    end

    it 'yields the block' do
      expect { |b| described_class.log(:arg, 'arg', &b) }.to yield_with_no_args
    end

    it 'logs the message' do
      expect(Rails.logger).to receive(:info).with(/arg/)
      described_class.log(:arg, 'arg') { true }
    end

    it 'returns the result of the block' do
      expect(described_class.log(:arg, 'arg') { 1 + 1 }).to eq(2)
    end

    context 'timing' do
      let!(:start_time) { Time.zone.now.utc }
      let!(:end_time) { start_time + 5.seconds }
      let!(:utc) { double('utc') }

      before do
        allow(utc).to receive(:utc).and_return(start_time, end_time)
        allow(Time).to receive(:now).twice.and_return(utc)
      end

      it 'calculates the run time of the block' do
        expect(Rails.logger).to receive(:info).with(/5000.00ms/)
        described_class.log(:arg, 'arg') { true }
      end
    end
  end
end

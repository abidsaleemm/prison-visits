require 'rails_helper'

RSpec.describe BookingConstraints, type: :model do
  subject { described_class.new(params) }

  let(:params) {
    {
      prison_id: prison_id,
      prisoner_number: prisoner_number,
      prisoner_dob: prisoner_dob
    }
  }
  let(:pvb_api) { PrisonVisits::Api.instance }
  let(:prison_id) { '123' }
  let(:prisoner_number) { 'a1234bc' }
  let(:prisoner_dob) { Date.parse('1970-01-01') }

  describe 'on visitors' do
    subject { super().on_visitors }

    it 'uses the API to fetch the adult age for the prison'
  end

  describe 'on slots' do
    subject { super().on_slots }

    before do
      allow(pvb_api).to receive(:get_slots).and_return([
        ConcreteSlot.new(2015, 1, 2, 9, 0, 10, 0),
        ConcreteSlot.new(2015, 1, 4, 9, 0, 10, 0),
        ConcreteSlot.new(2015, 1, 3, 9, 0, 10, 0)
      ])
    end

    it 'fetches available slots from the API' do
      expect(pvb_api).to receive(:get_slots).
        with(params.merge(use_nomis_slots: false))
      subject
    end

    it 'allows checking whether a date is bookable' do
      expect(subject.bookable_date?(Date.new(2015, 1, 2))).to be true
      expect(subject.bookable_date?(Date.new(2015, 2, 2))).to be false
    end

    it 'allows checking last bookable date' do
      expect(subject.last_bookable_date).to eq(Date.new(2015, 1, 4))
    end

    it 'can return whether there are available slots' do
      expect(subject.bookable_slots?).to be(true)
    end
  end
end

require 'rails_helper'

RSpec.describe VisitorsStep do
  subject { described_class.new(processor: processor) }

  let(:processor) {
    instance_double(StepsProcessor, booking_constraints: booking_constraints)
  }
  let(:booking_constraints) {
    instance_double(BookingConstraints, on_visitors: visitor_constraints)
  }
  let(:visitor_constraints) { BookingConstraints::VisitorConstraints.new }

  let(:adult) {
    {
      first_name: 'John',
      last_name: 'Johnson',
      date_of_birth: { day: '3', month: '4', year: '1990' }
    }
  }
  let(:child_13) {
    {
      first_name:  'Jim',
      last_name:  'Johnson',
      date_of_birth:  {
        day:  '1', month:  '12', year:  '2002' # 13 today
      }
    }
  }
  let(:child_12) {
    {
      first_name:  'Jessica',
      last_name:  'Johnson',
      date_of_birth:  {
        day:  '2', month:  '12', year:  '2002' # 13 tomorrow
      }
    }
  }
  let(:blank_visitor) {
    {
      first_name: '',
      last_name: '',
      date_of_birth: { day: '', month: '', year: '' }
    }
  }
  let(:invalid_visitor) {
    {
      first_name: '',
      last_name: 'Johnson',
      date_of_birth: { day: '3', month: '4', year: '1990' }
    }
  }

  around do |example|
    travel_to Date.new(2015, 12, 1) do
      example.call
    end
  end

  describe "email_address=" do
    it 'strips whitespace' do
      subject.email_address = ' email@example.com '
      expect(subject.email_address).to eq('email@example.com')
    end
  end

  describe 'backfilled_visitors' do
    it 'includes supplied visitors' do
      subject.visitors_attributes = {
        '0' => {
          'first_name' => 'Bob',
          'last_name' => 'Roberts',
          'date_of_birth' => { 'day' => '1', 'month' => '2', 'year' => '1980' }
        },
        '1' => {
          'first_name' => 'John',
          'last_name' => 'Johnson',
          'date_of_birth' => { 'day' => '3', 'month' => '4', 'year' => '1990' }
        }
      }
      expect(subject.backfilled_visitors[0]).to match(
        an_object_having_attributes(
          first_name: 'Bob',
          last_name: 'Roberts',
          date_of_birth: Date.new(1980, 2, 1)
        )
      )
      expect(subject.backfilled_visitors[1]).to match(
        an_object_having_attributes(
          first_name: 'John',
          last_name: 'Johnson',
          date_of_birth: Date.new(1990, 4, 3)
        )
      )
    end

    it 'returns blank visitors to make up 6' do
      subject.visitors_attributes = {}
      expect(subject.backfilled_visitors.length).to eq(6)
    end

    it 'includes and validates one visitor if none supplied' do
      subject.visitors_attributes = {}
      subject.valid?
      expect(subject.backfilled_visitors[0].errors).not_to be_empty
    end

    it 'does not validate blank additional visitors' do
      subject.visitors_attributes = {
        '0' => blank_visitor,
        '1' => blank_visitor
      }
      subject.validate
      expect(subject.backfilled_visitors[1].errors).to be_empty
    end
  end

  describe 'additional_visitor_count' do
    it 'is one less than the number of visitors supplied' do
      subject.visitors = [adult, child_12]
      expect(subject.additional_visitor_count).to eq(1)
    end
  end

  describe 'visitors' do
    it 'returns only visitors assigned with at least one field' do
      subject.visitors_attributes = {
        '0' => {
          'first_name' => 'Bob',
          'last_name' => 'Roberts',
          'date_of_birth' => { 'day' => '1', 'month' => '2', 'year' => '1980' }
        },
        '1' => {
          'first_name' => '',
          'last_name' => '',
          'date_of_birth' => { 'day' => '3', 'month' => '4', 'year' => '1990' }
        },
        '2' => {
          'first_name' => '',
          'last_name' => '',
          'date_of_birth' => { 'day' => '', 'month' => '', 'year' => '' }
        }
      }

      expect(subject.visitors.length).to eq(2)
    end

    it 'always returns at least one visitor' do
      subject.visitors_attributes = {}
      expect(subject.visitors.length).to eq(1)
    end
  end

  describe 'valid?' do
    before do
      subject.email_address = 'user@test.example.com'
      subject.phone_no = '01154960123'
    end

    it 'is true if the step is valid and all visitors are valid' do
      subject.visitors = [adult, adult]
      expect(subject).to be_valid
    end

    it 'is false if a visitor is invalid' do
      subject.visitors = [adult, invalid_visitor]
      expect(subject).not_to be_valid
    end

    it 'is false if there are no visitors' do
      subject.visitors = []
      expect(subject).not_to be_valid
    end

    it 'is invalid if there are too many visitors' do
      subject.visitors = [adult] * 3 + [child_12] * 4

      expect(subject).not_to be_valid
      expect(subject.errors).to have_key(:general)
      expect(subject.errors[:general]).to eq(
        ["You can book a maximum of 6 visitors"]
      )
    end

    it 'validates all objects even if one is invalid' do
      subject.email_address = 'invalid'
      subject.visitors = [invalid_visitor, invalid_visitor]
      subject.validate
      expect(subject.backfilled_visitors[0].errors).not_to be_empty
      expect(subject.backfilled_visitors[1].errors).not_to be_empty
      expect(subject.errors).not_to be_empty
    end
  end

  context 'age-related validations' do
    let(:visitor_constraints) {
      BookingConstraints::VisitorConstraints.new(adult_age: 13)
    }

    it 'is valid if there is one adult visitor' do
      subject.visitors = [adult]
      subject.validate
      expect(subject.errors).not_to have_key(:general)
    end

    it 'is valid if there are 3 adult and 3 child visitors' do
      subject.visitors = [child_13] * 3 + [child_12] * 3
      subject.validate
      expect(subject.errors).not_to have_key(:general)
    end

    it 'is invalid if there are too many adult visitors' do
      subject.visitors = [child_13] * 6
      subject.validate
      expect(subject.errors[:general]).to include(
        'You can book a maximum of 3 visitors over the age of 13 on this visit'
      )
    end

    it 'is invalid if there is no adult visitor' do
      subject.visitors = [child_12] * 2
      subject.validate
      expect(subject.errors[:general]).to include(
        'There must be at least one adult visitor'
      )
    end
  end
end

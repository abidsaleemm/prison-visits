class Visit
  include NonPersistedModel

  attribute :id
  attribute :confirm_by, Date
  attribute :slot_granted, ConcreteSlot, coercer: lambda { |slot|
    slot.nil? ? nil : ConcreteSlot.parse(slot)
  }
  attribute :contact_email_address
  attribute :slots, [ConcreteSlot], coercer: lambda { |slots|
    slots.map { |s| ConcreteSlot.parse(s) }
  }
  attribute :prison_id
  attribute :processing_state, Symbol, coercer: lambda { |state|
    VALID_STATES.find { |s| s.to_s == state } ||
      fail("Invalid processing_state for visit: #{state}")
  }

  attribute :visitors, [Visitor], coercer: lambda { |visitors|
    visitors.map { |v| Visitor.new(v) }
  }
  attribute :cancellation_reason, Symbol
  attribute :cancelled_at, DateTime
  attribute :can_cancel, Boolean
  attribute :can_withdraw, Boolean
  VALID_STATES = %i[ requested withdrawn booked cancelled rejected ]

  delegate :address, :email_address, :name, :phone_no, :postcode,
    to: :prison, prefix: true
  delegate :prison_finder_url, to: :prison

  def allowed_visitors
    visitors.select(&:allowed)
  end

  def rejected_visitors
    visitors.reject(&:allowed)
  end

  def can_cancel?
    can_cancel
  end

  def can_withdraw?
    can_withdraw
  end

private

  def prison
    # Memoize since this does an API lookup
    @_prison ||= Prison.find_by_id(prison_id)
  end
end

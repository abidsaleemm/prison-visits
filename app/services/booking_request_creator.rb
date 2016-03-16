class BookingRequestCreator
  # rubocop:disable Metrics/MethodLength
  def create!(prisoner_step, visitors_step, slots_step, locale)
    prisoner = prisoner_step.to_hash.except(:prison_id)
    visitors = visitors_step.visitors.map(&:to_hash)

    params = {
      prison_id: prisoner_step.prison_id,
      prisoner: prisoner,
      visitors: visitors,
      contact_email_address: visitors_step.email_address,
      contact_phone_no: visitors_step.phone_no,
      slot_options: [
        slots_step.option_0,
        slots_step.option_1,
        slots_step.option_2
      ],
      locale: locale
    }

    visit = Rails.configuration.pvb_api.request_booking(params)
    visit
  end
  # rubocop:enable Metrics/MethodLength
end

module PrisonVisits
  class Api
    def initialize(api_client)
      @client = api_client
    end

    def get_prisons
      result = @client.get('/prisons')
      result['prisons'].map { |params| Prison.new(params) }
    end

    def get_prison(prison_id)
      result = @client.get("/prisons/#{prison_id}")
      Prison.new(result['prison'])
    end

    def get_slots(prison_id)
      response = @client.get('/slots', prison_id: prison_id)
      response['slots'].map { |s| ConcreteSlot.parse(s) }
    end

    def request_booking(params)
      response = @client.post('/bookings', params)
      Visit.new(response.fetch('visit'))
    end

    def get_visit(id)
      response = @client.get("bookings/#{id}")
      Visit.new(response.fetch('visit'))
    end

    def cancel_visit(id)
      response = @client.delete("bookings/#{id}")
      Visit.new(response.fetch('visit'))
    end
  end
end

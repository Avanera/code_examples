module HelpcrunchApi
  class Endpoints
    def initialize
      @client = Client.new.class
    end

    def fetch_helpcrunch_customer(user, create_if_not_found: false)
      query = { filter: [field: 'customers.email', operator: '=', value: user.email] }.to_json
      request_result = @client.post(
        '/customers/search',
        body: query
      )

      return request_result['data'][0].with_indifferent_access if request_result['errors'].blank?

      need_to_raise_error = request_result['errors'] && !create_if_not_found
      raise CustomerNotFoundError, 'Customer Not Found' if need_to_raise_error

      create_customer(user).with_indifferent_access
    end

    def create_customer(user)
      # create customer stub
    end
  end
end

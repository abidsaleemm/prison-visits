require 'excon'

class PrisonVisitsAPI
  def initialize(host)
    @host = host
    @connection = Excon.new(host, persistent: true)
  end

  def get(route, params = {})
    request(:get, route, params)
  end

  def post(route, params)
    request(:post, route, params)
  end

  def delete(route, params = {})
    request(:delete, route, params)
  end

private

  # rubocop:disable Metrics/MethodLength
  def request(method, route, params)
    # For cleanliness, strip initial / if supplied
    route = route.sub(%r{^\/}, '')
    path = "/api/#{route}.json"

    options = {
      method: method,
      path: path,
      expects: [200],
      headers: {
        'Accept' => 'application/json',
        'Accept-Language' => 'en'
      }
    }.deep_merge(params_options(method, params))

    response = @connection.request(options)

    JSON.parse(response.body)
  end
  # rubocop:enable Metrics/MethodLength

  # Returns excon options which put params in either the query string or body.
  def params_options(method, params)
    return {} if params.empty?

    if method == :get || method == :delete
      { query: params }
    else
      b = params.respond_to?(:to_json) ? params.to_json : JSON.generate(params)
      {
        body: b,
        headers: { 'Content-Type' => 'application/json' }
      }
    end
  end
end

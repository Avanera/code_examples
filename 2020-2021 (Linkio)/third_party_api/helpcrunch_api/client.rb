module HelpcrunchApi
  class Client
    include HTTParty

    default_timeout 20
    base_uri(Rails.application.secrets.helpcrunch_url)
    headers Authorization: "Bearer #{Rails.application.secrets.helpcrunch_api_key}"

    uri_adapter Addressable::URI
  end
end

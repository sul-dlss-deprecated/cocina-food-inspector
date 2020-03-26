# shameless rip-off of https://github.com/sul-dlss/dor-services-client/blob/master/lib/dor/services/client.rb
# and other methods, TODO: should prob just add ObjectsController#show wrapper to DSC and consume that gem in this app

class DsaClient
  TOKEN_HEADER = 'Authorization'
  API_VERSION = 'v1'

  def self.object_show(druid)
    conn = connection(Settings.dor_services.url)
    resp = conn.get do |req|
      req.url "#{API_VERSION}/objects/#{druid}"
      req.headers['Content-Type'] = 'application/json'
      # asking the service to return JSON (else it'll be plain text)
      req.headers['Accept'] = 'application/json'
    end
  end

  def self.connection(url)
    Faraday.new(url) do |builder|
      builder.use Faraday::Response::Middleware
      builder.use Faraday::Request::UrlEncoded

      # @note when token & token_header are nil, this line is required else
      #       the Faraday instance will be passed an empty block, which
      #       causes the adapter not to be set. Thus, everything breaks.
      builder.adapter Faraday.default_adapter
      builder.headers[:user_agent] = user_agent
      builder.headers[TOKEN_HEADER] = "Bearer #{Settings.dor_services.token}"
    end
  end

  def self.user_agent
    "cocina-food-inspector"
  end
end
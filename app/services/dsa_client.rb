# shameless rip-off of https://github.com/sul-dlss/dor-services-client/blob/master/lib/dor/services/client.rb
# and other methods, TODO: should prob just add ObjectsController#show wrapper to DSC and consume that gem in this app

require 'fileutils'

class DsaClient
  TOKEN_HEADER = 'Authorization'
  API_VERSION = 'v1'



  # TODO: should maybe break this method out to separate class to keep the client focused
  # purely on connection wrangling?
  def self.try_retrieval_and_log_result(druid)
    Rails.logger.info("retrieving #{druid}")
    response = object_show(druid)
    if response.status == 200
      Rails.logger.info("success: 200 OK retrieving #{druid}")
      write_cocina_success_to_file(druid, response)
    else
      Rails.logger.warn("failure: #{response.status} #{response.reason_phrase} retrieving #{druid} : #{response.body}")
      write_cocina_failure_to_file(druid, response)
    end

    response
  end

  def self.write_cocina_success_to_file(req_druid, response)
    return unless Settings.cocina_output.success.should_output
    write_druid_response_to_file(Settings.cocina_output.success.location, req_druid, JSON.pretty_generate(response.to_hash))
  end

  def self.write_cocina_failure_to_file(req_druid, response)
    return unless Settings.cocina_output.failure.should_output
    write_druid_response_to_file(Settings.cocina_output.failure.location, req_druid, JSON.pretty_generate(response.to_hash))
  end

  def self.write_druid_response_to_file(output_path, req_druid, druid_output)
    output_filename = File.join(output_path, druid_path(req_druid))
    self.ensure_containing_dir(output_filename)
    File.open(output_filename, 'w') do |file|
      file.write(druid_output)
    end
  end

  # broken out into its own method because we'll likely want to use druid
  # trees or pair trees when we get into running this against everything
  def self.druid_path(druid)
    File.join(druid, "#{current_time_str}.json")
  end

  def self.current_time_str
    DateTime.now.utc.iso8601.to_s
  end

  def self.ensure_containing_dir(filename)
    basename_len = File.basename(filename).length
    filepath_str = filename[0..-(basename_len + 1)] # add 1 to basename_len because ending at -1 gets the whole string
    FileUtils.mkdir_p(filepath_str) unless FileTest.exist?(filepath_str)
  end



  # TODO: below this is what i think actually belongs in this class
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
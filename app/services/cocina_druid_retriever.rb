require 'fileutils'
require 'dsa_client'

class CocinaDruidRetriever
  attr_reader :druid

  def initialize(druid)
    @druid = druid
  end

  def self.try_retrieval_and_log_result(druid)
    new(druid).try_retrieval_and_log_result
  end

  def try_retrieval_and_log_result
    Rails.logger.info("retrieving #{druid}")
    response = DsaClient.object_show(druid)
    if response.status == 200
      Rails.logger.info("success: 200 OK retrieving #{druid}")
      write_cocina_success_to_file(response)
    else
      Rails.logger.warn("failure: #{response.status} #{response.reason_phrase} retrieving #{druid} : #{response.body}")
      write_cocina_failure_to_file(response)
    end

    response
  end

  private

  def write_cocina_success_to_file(response)
    return unless Settings.cocina_output.success.should_output
    write_druid_response_to_file(Settings.cocina_output.success.location, JSON.pretty_generate(response.to_hash))
  end

  def write_cocina_failure_to_file(response)
    return unless Settings.cocina_output.failure.should_output
    write_druid_response_to_file(Settings.cocina_output.failure.location, JSON.pretty_generate(response.to_hash))
  end

  def write_druid_response_to_file(output_path, druid_output)
    output_filename = File.join(output_path, druid_path)
    ensure_containing_dir(output_filename)
    File.open(output_filename, 'w') do |file|
      file.write(druid_output)
    end
  end

  # broken out into its own method because we'll likely want to use druid
  # trees or pair trees when we get into running this against everything
  def druid_path
    File.join(druid, "#{current_time_str}.json")
  end

  def current_time_str
    DateTime.now.utc.iso8601.to_s
  end

  def ensure_containing_dir(filename)
    basename_len = File.basename(filename).length
    filepath_str = filename[0..-(basename_len + 1)] # add 1 to basename_len because ending at -1 gets the whole string
    FileUtils.mkdir_p(filepath_str) unless FileTest.exist?(filepath_str)
  end
end

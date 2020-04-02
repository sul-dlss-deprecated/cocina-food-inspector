class Util
  def self.exception_msg_and_backtrace_str(exception)
    "#{exception}\n#{exception&.full_message}"
  end

  def self.faraday_response_to_json(response)
    JSON.pretty_generate(response.to_hash)
  rescue StandardError => e
    Rails.logger.error("Unexpected error generating JSON from response: #{Util.exception_msg_and_backtrace_str(e)}")
    response.to_hash.to_s
  end
end

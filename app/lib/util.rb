class Util
  def self.exception_msg_and_backtrace_str(exception)
    "#{exception}\n#{exception&.full_message}"
  end
end

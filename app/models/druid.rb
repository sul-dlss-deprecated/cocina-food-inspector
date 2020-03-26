class Druid < ApplicationRecord
  has_many :druid_retrieval_attempts, inverse_of: :druid

  # you probably want to use a limit clause on this, and/or iterate over results using #find_each
  scope :unretrieved, lambda {
    where.not(
      id: DruidRetrievalAttempt.select(:druid_id).distinct
    )
  }

  # assumes one druid per line.  dupes are fine, should just add the new ones.
  # limit_adds: add up to this many druids to the DB
  # limit_readlines: read up to this many lines
  def self.add_new_druids_from_file(filename, limit_adds: nil, limit_readlines: nil)
    druid_file = File.open(filename)
    num_adds = 0
    num_lines_read = 0
    Rails.logger.debug("filename=#{filename} ; limit_adds=#{limit_adds} ; limit_readlines=#{limit_readlines}")

    cur_druid = ""
    while(cur_druid) do
      cur_druid = druid_file.readline&.chomp
      num_lines_read += 1
      Rails.logger.debug("Druid.add_new_druids_from_file: cur_druid=#{cur_druid}")

      break unless cur_druid
      break if limit_adds && num_adds >= limit_adds
      break if limit_readlines && num_lines_read >= limit_readlines

      begin
        create!(druid: cur_druid)
        num_adds += 1
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.info("Druid.add_new_druids_from_file: #{cur_druid} already in DB")
      rescue StandardError => e
        Rails.logger.error("Druid.add_new_druids_from_file: Unexpected error adding #{cur_druid} to DB: #{e}")
      end
    end

    Rails.logger.debug("Druid.add_new_druids_from_file: finished -- num_lines_read=#{num_lines_read} ; num_adds=#{num_adds}")
  end
end

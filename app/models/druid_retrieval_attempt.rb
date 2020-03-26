class DruidRetrievalAttempt < ApplicationRecord
  belongs_to :druid
  # TODO: need to add retrieval_source, i.e. cocina mapper or fedora
  # TODO: migration didn't seem to enforce foreign key relationship (at DB level) to druids entry from this table
end

class CreateDruidRetrievalAttempts < ActiveRecord::Migration[5.2]
  def change
    create_table :druid_retrieval_attempts do |t|
      t.references :druid, foreign_key: true
      t.integer :response_status
      t.string :response_reason_phrase
      t.string :output_path

      t.timestamps
    end
  end
end

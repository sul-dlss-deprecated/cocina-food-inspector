class CreateDruids < ActiveRecord::Migration[5.2]
  def change
    create_table :druids do |t|
      t.string :druid
      t.index :druid, unique: true

      t.timestamps
    end
  end
end

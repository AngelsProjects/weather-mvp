class CreateSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :searches do |t|
      t.string :location, null: false
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false

      t.timestamps
    end

    add_index :searches, :created_at
  end
end

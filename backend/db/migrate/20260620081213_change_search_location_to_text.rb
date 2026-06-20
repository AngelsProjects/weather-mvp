class ChangeSearchLocationToText < ActiveRecord::Migration[7.1]
  # location is encrypted at rest (Active Record Encryption). Ciphertext is
  # longer than the plaintext, so a 255-char varchar can overflow. Widen to text.
  def up
    change_column :searches, :location, :text
  end

  def down
    change_column :searches, :location, :string
  end
end

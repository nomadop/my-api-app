class CreateEmails < ActiveRecord::Migration[5.0]
  def change
    create_table :emails do |t|
      t.string :from
      t.string :to
      t.string :message_id
      t.string :subject
      t.text :body
      t.timestamp :date

      t.timestamps
    end
    add_index :emails, :message_id, unique: true
    add_index :emails, :date
    add_index :emails, :to
  end
end

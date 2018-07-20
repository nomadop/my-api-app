class SorceryCore < ActiveRecord::Migration[5.0]
  def change
    create_table :admins do |t|
      t.string :email,            :null => false
      t.string :crypted_password
      t.string :salt

      t.timestamps                :null => false
    end

    add_index :admins, :email, unique: true
  end
end

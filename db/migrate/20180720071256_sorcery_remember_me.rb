class SorceryRememberMe < ActiveRecord::Migration[5.0]
  def change
    add_column :admins, :remember_me_token, :string, :default => nil
    add_column :admins, :remember_me_token_expires_at, :datetime, :default => nil

    add_index :admins, :remember_me_token
  end
end

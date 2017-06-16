class AddUnavailableAndAvailableAtTimeToAccountBoosterCreators < ActiveRecord::Migration[5.0]
  def change
    add_column :account_booster_creators, :unavailable, :boolean, default: false
    add_column :account_booster_creators, :available_at_time, :string
  end
end

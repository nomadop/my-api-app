class AddAvailabilityToBoosterCreators < ActiveRecord::Migration[5.0]
  def change
    add_column :booster_creators, :unavailable, :boolean, default: false
    add_column :booster_creators, :available_at_time, :string
  end
end

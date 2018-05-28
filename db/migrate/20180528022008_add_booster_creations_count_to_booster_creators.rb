class AddBoosterCreationsCountToBoosterCreators < ActiveRecord::Migration[5.0]
  def change
    add_column :booster_creators, :booster_creations_count, :integer
  end
end

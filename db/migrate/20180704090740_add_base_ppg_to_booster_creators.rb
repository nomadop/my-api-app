class AddBasePpgToBoosterCreators < ActiveRecord::Migration[5.0]
  def change
    add_column :booster_creators, :base_ppg, :float
  end
end

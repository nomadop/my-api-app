class CreateOrderActivities < ActiveRecord::Migration[5.0]
  def change
    create_table :order_activities do |t|
      t.string :item_nameid
      t.string :content
      t.string :user1_name
      t.string :user1_avatar
      t.string :user2_name
      t.string :user2_avatar
      t.integer :price

      t.timestamps
    end
    add_index :order_activities, :content, unique: :true
  end
end

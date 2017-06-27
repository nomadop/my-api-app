class AddListedDateToMyHistories < ActiveRecord::Migration[5.0]
  def change
    add_column :my_histories, :listed_date, :string
  end
end

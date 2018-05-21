class CreateJobConcurrences < ActiveRecord::Migration[5.0]
  def change
    create_table :job_concurrences do |t|
      t.string :uuid, null: false
      t.integer :concurrence, default: 0
      t.integer :limit, default: 0
      t.integer :limit_type, default: 0
      t.integer :lock_version, default: 0

      t.timestamps
    end
    add_index :job_concurrences, :uuid, unique: true
  end
end

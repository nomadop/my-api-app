class CreateJobLocks < ActiveRecord::Migration[5.0]
  def change
    create_table :job_locks do |t|
      t.string :name, null: false
      t.boolean :locked, default: false
      t.integer :lock_version, default: 0

      t.timestamps
    end
    add_index :job_locks, :name, unique: true
  end
end

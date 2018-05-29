class ChangeColumnsOfJobConcurrences < ActiveRecord::Migration[5.0]
  def up
    remove_column :job_concurrences, :limit
    remove_column :job_concurrences, :concurrence
    remove_column :job_concurrences, :lock_version
    add_column :job_concurrences, :limit, :integer
    add_column :job_concurrences, :job_id, :string
    add_index :job_concurrences, [:uuid, :limit], unique: true
  end

  def down
    remove_column :job_concurrences, :limit
    remove_column :job_concurrences, :job_id
    add_column :job_concurrences, :limit, :integer, default: 0
    add_column :job_concurrences, :concurrence, :integer, default: 0
    add_column :job_concurrences, :lock_version, :integer, default: 0
    add_index :job_concurrences, [:uuid, :limit], unique: true
  end
end

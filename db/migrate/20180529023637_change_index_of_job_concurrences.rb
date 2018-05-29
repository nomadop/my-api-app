class ChangeIndexOfJobConcurrences < ActiveRecord::Migration[5.0]
  def change
    remove_index :job_concurrences, :uuid
    add_index :job_concurrences, [:uuid, :limit], unique: true
  end
end

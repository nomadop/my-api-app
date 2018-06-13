class AddDelegatedToJobConcurrences < ActiveRecord::Migration[5.0]
  def change
    add_column :job_concurrences, :delegated, :boolean, default: false
  end
end

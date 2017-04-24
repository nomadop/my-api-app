class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.truncate
    self.connection_pool.with_connection { |c| c.truncate(table_name) }
  end
end

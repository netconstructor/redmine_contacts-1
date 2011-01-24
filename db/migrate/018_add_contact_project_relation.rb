class AddContactProjectRelation < ActiveRecord::Migration
  def self.up
    add_column :projects, :contact_id, :integer
  end

  def self.down
    remove_column :projects, :contact_id
  end
  
end
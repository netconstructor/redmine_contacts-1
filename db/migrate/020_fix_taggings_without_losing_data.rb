class FixTaggingsWithoutLosingData < ActiveRecord::Migration
  def self.up
    return unless self.table_exists?("taggings")
    
    remove_index :taggings, :column => [:container_id, :container_type]
    rename_column :taggings, :container_id, :taggable_id
    rename_column :taggings, :container_type, :taggable_type
    
    add_column :taggings, :created_ad, :datetime
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type]
  end

  def self.down
    return unless self.table_exists?("taggings")
    
    rename_column :taggings, :taggable_id, :container_id
    rename_column :taggings, :taggable_type, :container_type
    remove_column :taggings, :created_ad, :datetime
    
    add_index :taggings, [:container_id, :container_type]

  end

  #######
  private
  #######
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
    
  end
end

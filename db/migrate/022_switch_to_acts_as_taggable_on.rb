class SwitchToActsAsTaggableOn < ActiveRecord::Migration
  def self.up
    return unless self.table_exists?("taggings")
    
    remove_index :taggings, [:taggable_id, :taggable_type]
    remove_column :tags, :color
    
    add_column :taggings, :id, :integer
    add_column :taggings, :tagger_id, :integer
    add_column :taggings, :tagger_type, :string
    add_column :taggings, :context, :string
    
    add_index :taggings, [:taggable_id, :taggable_type, :context]
    
    require 'acts_as_taggable_on'
    
    say "Updating Tagging ids"
    counter = 1
    Tagging.find(:all, :conditions => "id IS NULL").each do |t|
      execute "UPDATE taggings SET id = #{counter}, context = 'tags' WHERE tag_id = #{t.tag_id} AND taggable_id = #{t.taggable_id} AND taggable_type = '#{t.taggable_type}'"
      say "setting ID #{t.id}"
      counter += 1
    end
    
  end

  def self.down
    return unless self.table_exists?("taggings")
    
    remove_index :taggings, [:taggable_id, :taggable_type, :context]
    add_column :tags, :color, :integer
    
    remove_column :taggings, :id
    remove_column :taggings, :tagger_id
    remove_column :taggings, :tagger_type
    remove_column :taggings, :context
    
    add_index :taggings, [:taggable_id, :taggable_type]

  end

  #######
  private
  #######
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
    
  end
end

class CreateTaggings < ActiveRecord::Migration
  def self.up
    return if self.table_exists?("taggings")

    create_table :taggings, :id => false do |t|
      t.column :tag_id, :integer
      t.column :container_id, :integer
      t.column :container_type, :string
    end

    add_index :taggings, [:container_id, :container_type]

  end


  def self.down
    drop_table :taggings if self.table_exists?("taggings")
  end
  
  #######
  private
  #######
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end
  
end
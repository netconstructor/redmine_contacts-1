class CreateTags < ActiveRecord::Migration
  def self.up
    return if self.table_exists?("tags")
    create_table :tags do |t|
      t.column :name, :string
      t.timestamps
    end
    add_index :tags, :name
  end
  

  def self.down 
    drop_table :tags if self.table_exists?("tags")
  end
  
  #######
  private
  #######
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end
end

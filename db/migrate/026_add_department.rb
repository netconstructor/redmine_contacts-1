class AddDepartment < ActiveRecord::Migration
  def self.up
    return if self.table_exists?("rc_departments")
    create_table :rc_departments do |t|
      t.column :name, :string
      t.timestamps
    end
    
    Department.create(:name => "sinnbild")
    Department.create(:name => "sinnternet")
    Department.create(:name => "sinnema")
    Department.create(:name => "sinnvention")
    
    add_index :rc_departments, :name
  end
  

  def self.down 
    drop_table :rc_departments
  end
  
  #######
  private
  #######
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end
end

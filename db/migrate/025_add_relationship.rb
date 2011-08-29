class AddRelationship < ActiveRecord::Migration
  def self.up
    return if self.table_exists?("rc_relationships")
    create_table :rc_relationships do |t|
      t.column :name, :string
      t.timestamps
    end
    
    Relationship.create(:name => "Freunde")
    Relationship.create(:name => "Kunde")
    Relationship.create(:name => "Mitarbeiter")
    Relationship.create(:name => "Partner")
    Relationship.create(:name => "Team")
    Relationship.create(:name => "Potenzieller Kunde")
    
    add_index :rc_relationships, :name
  end
  

  def self.down 
    drop_table :rc_relationships
  end
  
  #######
  private
  #######
  def self.table_exists?(name)
    ActiveRecord::Base.connection.tables.include?(name)
  end
end

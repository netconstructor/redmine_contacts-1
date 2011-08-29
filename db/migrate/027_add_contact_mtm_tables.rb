class AddContactMtmTables < ActiveRecord::Migration
  def self.up
    create_table :rc_contacts_departments, :id => false do |t|
      t.references :contact
      t.references :department
    end
    
    create_table :rc_contacts_relationships, :id => false do |t|
      t.references :contact
      t.references :relationship
    end
  end
  

  def self.down 
    drop_table :rc_contacts_departments
    drop_table :rc_contacts_relationships
  end
  
end

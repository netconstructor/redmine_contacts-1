class Relationship < ActiveRecord::Base
  unloadable
  set_table_name "rc_relationships"
  
  has_and_belongs_to_many :contacts, :join_table => :rc_contacts_relationships
  
  validates_presence_of :name
end
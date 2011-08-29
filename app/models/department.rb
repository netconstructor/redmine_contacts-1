class Department < ActiveRecord::Base
  unloadable
  set_table_name "rc_departments"
  
  has_and_belongs_to_many :contacts, :join_table => :rc_contacts_departments
  
  validates_presence_of :name
end
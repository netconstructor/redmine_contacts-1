class AddBirthdayInfo < ActiveRecord::Migration
  def self.up
    change_column(:contacts, :birthday, :date)    
  end

  def self.down
    change_column(:contacts, :birthday, :datetime)
  end
  
end
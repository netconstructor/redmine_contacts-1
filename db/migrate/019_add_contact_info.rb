class AddContactInfo < ActiveRecord::Migration
  def self.up
    add_column :contacts, :customer_number, :integer
    add_column :contacts, :bank_account, :integer
    add_column :contacts, :bank_code, :string
  end

  def self.down
    rename_column :contacts, :customer_number
    rename_column :contacts, :bank_account
    rename_column :contacts, :bank_code
  end
  
end
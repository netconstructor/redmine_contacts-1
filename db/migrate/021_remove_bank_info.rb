class RemoveBankInfo < ActiveRecord::Migration

  def self.up
    remove_column :contacts, :bank_account
    remove_column :contacts, :bank_code
  end
  
  def self.down
    add_column :contacts, :bank_account, :integer
    add_column :contacts, :bank_code, :string
  end
  
end
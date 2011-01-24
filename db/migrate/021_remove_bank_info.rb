class RemoveBankInfo < ActiveRecord::Migration

  def self.up
    remove_column :contacts, :bank_account
    remove_column :contacts, :bank_code
    rename_column :taggings, :created_ad, :created_at
    
  end
  
  def self.down
    rename_column :taggings, :created_at, :created_ad
    add_column :contacts, :bank_account, :integer
    add_column :contacts, :bank_code, :string
  end
  
end
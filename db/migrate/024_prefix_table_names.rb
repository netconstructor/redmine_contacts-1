class PrefixTableNames < ActiveRecord::Migration
  def self.up
    rename_table :contacts, "rc_contacts"
    rename_table :contacts_issues, "rc_contacts_issues"
    rename_table :deals, "rc_deals"
    rename_table :notes, "rc_notes"
  end

  def self.down
    rename_table :rc_contacts, :contacts
    rename_table :rc_contacts_issues, :contacts_issues
    rename_table :rc_deals, :deals
    rename_table :rc_notes, :notes
  end
end
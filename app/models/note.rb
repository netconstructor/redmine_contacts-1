class Note < ActiveRecord::Base   
  unloadable
  
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :source, :polymorphic => true
  
  validates_presence_of :source, :author, :content

  
  after_create :send_mails  
  
  acts_as_attachable :view_permission => :view_contacts,  
                     :delete_permission => :edit_contacts   
                    
  acts_as_event :title => Proc.new {|o| "#{l(:label_note_for)}: #{o.source.name}"}, 
                :type => "issue-note", 
                :url => Proc.new {|o| {:controller => o.source.class.name.pluralize.downcase, :action => 'show', :id => o.source.id }},
                :description => Proc.new {|o| o.content}      
                                                                               
  def editable_by?(usr)   
    usr ||= self.author
    usr.allowed_to?(:add_note, nil, {:global => true})    
  end

  def destroyable_by?(usr)
    usr ||= self.author
    usr.allowed_to?(:delete_notes, nil, {:global => true})                              
  end
  
  def self.recent_notes(contacts)
    last_notes = Note.find(:all, 
                           :conditions => { :source_type => "Contact", :source_id => contacts.map(&:id)}, 
                           :limit => count,
                           :order => "created_on DESC").collect{|obj| obj if obj.source.visible?}.compact
  end
  
  private
  
  def send_mails   
    if self.source.class == Contact && !self.source.is_company
      parent = Contact.find_by_first_name(self.source.company)
    end
    Mailer.deliver_note_added(self, parent)
  end
  

end
                    


class Contact < ActiveRecord::Base
  unloadable
  set_table_name "rc_contacts"

  require 'acts-as-taggable-on'  
  acts_as_taggable
  
  has_many :projects
  has_many :notes, :as => :source, :dependent => :delete_all, :order => "created_on DESC" 
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'    
  has_and_belongs_to_many :issues, :order => "#{Issue.table_name}.due_date", :uniq => true, :join_table => :rc_contacts_issues
  has_and_belongs_to_many :deals
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_and_belongs_to_many :departments, :join_table => :rc_contacts_departments
  has_and_belongs_to_many :relationships, :join_table => :rc_contacts_relationships
  
  attr_accessor :phones     
  attr_accessor :emails 
  
  acts_as_watchable

  acts_as_attachable :view_permission => :view_contacts,  
                     :delete_permission => :edit_contacts

  acts_as_event :datetime => :created_on,
                :url => Proc.new {|o| {:controller => 'contacts', :action => 'show', :id => o}}, 	
                :type => Proc.new {|o| 'contact' },  
                :title => Proc.new {|o| o.name },
                :description => Proc.new {|o| o.notes }     
                                
  # name or company is mandatory
  validates_presence_of :first_name
  validate :must_have_department
  validate :must_have_relationship
  
  
  validates_uniqueness_of :first_name, :scope => [:last_name, :middle_name, :company]

  validates_numericality_of :customer_number, :allow_blank => true
  
  named_scope :by_last_name, :order => "last_name, first_name"
  named_scope :with_relationship, lambda { |relationships|
       { :joins => :relationships, :conditions => ['rc_contacts_relationships.relationship_id IN (?)', relationships.map(&:id)] }
     }
  named_scope :with_department, lambda { |departments|
      { :joins => :departments, :conditions => ['rc_contacts_departments.department_id IN (?)', departments.map(&:id)] }
    }
  
  
  def visible?(usr=nil)
    (usr || User.current).allowed_to?(:view_contacts, nil, {:global => true})
  end
  
  def name
    result = []
    if !self.is_company
      [self.last_name, self.first_name, self.middle_name].each {|field| result << field unless field.blank?}
    else
      result << self.first_name
    end    

    return result.join(" ")
  end
   
  def phones                            
    @phones || self.phone ? self.phone.split( /, */) : []
  end   
  
  def emails                            
    @emails || self.email ? self.email.split( /, */) : []
  end
  
  # XXX: Attachments currently fail without a project.  The following methods act as overrides.
  
  # This overrides the instance method in acts_as_attachable
  def attachments_visible?(user=User.current)
    user.allowed_to?(:view_contacts, nil, {:global => true})
  end

  def attachments_deletable?(user=User.current)
    user.allowed_to?(:edit_contacts, nil, {:global => true})
  end
  
  def project
    nil
  end
  
  private
  
  def assign_phone      
    if @phones
      self.phone = @phones.uniq.map {|s| s.strip.delete(',').squeeze(" ")}.join(', ')
    end
  end
  
  def must_have_department
    self.errors.add(:department, "must have be specified") if self.departments.empty?
  end
  
  def must_have_relationship
    self.errors.add(:relationship, "must have be specified") if self.relationships.empty?
  end
  
end

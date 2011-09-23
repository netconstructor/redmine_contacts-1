require_dependency 'project'   
require_dependency 'projects_controller'
require_dependency 'dispatcher'
 
# Patches Redmine's Projects dynamically. Adds a relationship to contacts
# Contact +has_many+ Projects / Project +belongs_to+ Contact

module ContactsProjectPatch   
  
  def self.included(base) # :nodoc: 
    
    base.extend(ClassMethods)
 
    base.send(:include, InstanceMethods)
    
    # Same as typing in the class
    base.class_eval do    
      unloadable # Send unloadable so it will not be unloaded in development
      belongs_to :contact
      
      safe_attributes 'contact_id'
    end  
    
    
  end  
  
  module ClassMethods
  end

  module InstanceMethods
  end
  
end

module ContactsProjectsControllerPatch
  def self.included(base) # :nodoc: 
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)

    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      
      helper "contacts" 
      
    end
  end 

  module ClassMethods
  end  
  
  module InstanceMethods
  end

end

Dispatcher.to_prepare do
  Project.send(:include, ContactsProjectPatch)
  ProjectsController.send(:include, ContactsProjectsControllerPatch)  
end
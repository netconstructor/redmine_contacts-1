ActionController::Routing::Routes.draw do |map|
  map.contacts_tagged 'contacts/filter/*filters', :controller => 'contacts', :action => 'filter'
  map.contacts 'contacts', :controller => 'contacts', :action => 'index'
  map.connect 'contacts/:action', :controller => 'contacts'
  map.connect 'contacts/:action/:id', :controller => 'contacts'
end

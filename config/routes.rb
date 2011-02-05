ActionController::Routing::Routes.draw do |map|
  map.contacts_tagged 'contacts/tagged/*tags', :controller => 'contacts', :action => 'tagged'
  map.contacts 'contacts', :controller => 'contacts', :action => 'index'
  map.connect 'contacts/:action', :controller => 'contacts'
  map.connect 'contacts/:action/:id', :controller => 'contacts'
end

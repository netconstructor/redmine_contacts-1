module ContactsHelper

  def skype_to(skype_name, name = nil)
    return link_to skype_name, 'skype:' + skype_name + '?call' unless skype_name.blank?
  end
  
  def contacts_paginator(paginator, page_options)
    pagination_links_each(paginator, page_options) do |link|
        options = { :url => {:controller => 'contacts',  :action => 'live_search', :search => '', :project_id => @project, :params => params.merge({:page => link})}, :update => 'contact_list' }
        html_options = { :href => url_for(:controller => 'contacts',  :action => 'live_search', :project_id => @project, :params => params.merge({:page => link})) }
        # debugger
        link_to_remote(link.to_s, options)
    end
  end
  
  def contact_url(contact)       
    return {:controller => 'contacts', :action => 'show', :project_id => contact.project, :id => contact.id }
  end

  def note_source_url(note_source)       
    return {:controller => note_source.class.name.pluralize.downcase, :action => 'show', :project_id => note_source.project, :id => note_source.id }
  end
       
  def link_to_contact(contact) 
    return link_to contact.name, contact_url(contact)
  end

  def avatar_to(obj, options = { })  
    options[:size] = "64" unless options[:size]  
    options[:size] = options[:size] + "x" + options[:size] 
    options[:class] = "gravatar"  
    
    avatar = obj.attachments.find_by_description 'avatar'
    if avatar  then  # and obj.visible?
      image_url = url_for :only_path => false, :controller => 'attachments', :action => 'download', :id => avatar, :filename => avatar.filename
      # image_url = url_for :only_path => false, :controller => 'contacts', :action => 'download_avatar', :id => obj, :filename => avatar.filename
      
      return image_tag(image_url, options)
    elseif obj.email.downcase
      return gravatar(obj.email, options) rescue nil 
    else
      
      plugins_images  =  "/plugin_assets/redmine_contacts/images/"
      if obj.class == Deal   
        image =  image_tag(plugins_images + "deal.png", options)
      end  
      
      if obj.class == Contact
        image =  obj.is_company ? image_tag(plugins_images + "company.png", options) : image_tag(plugins_images + "person.png", options)
      end
      
      return image  
    end
  end
  
  def link_to_add_phone(name)             
    fields = '<p>' + label_tag(l(:field_contact_phone)) + 
      text_field_tag( "contact[phones][]", '', :size => 30 ) + 
      link_to_function(l(:label_remove), "removeField(this)") + '</p>'
    link_to_function(name, h("addField(this, '#{escape_javascript(fields)}' )"))
  end    
  
  def link_to_task_complete(url, bucket)
    onclick = "this.disable();"
    onclick << %Q/$("#{dom_id(pending, :name)}").style.textDecoration="line-through";/
    onclick << remote_function(:url => url, :method => :put, :with => "{ bucket: '#{bucket}' }")
  end
  
end

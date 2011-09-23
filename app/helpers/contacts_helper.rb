module ContactsHelper
  
  def authorize_for_global(symbol)
    User.current.allowed_to?(symbol, nil, {:global => true})
  end
  
  def render_project_hierarchy_with_contacts(projects)
    output = ''
    if projects.any?
      contacts = []
      orphans = []
      original_project = @project
      
      projects.each do |project|
        # set the project environment to please macros.
        @project = project
        if @project.contact.blank?
          orphans << @project
        else
          contacts << @project.contact unless contacts.include? @project.contact
        end
      end
      
      sorted = contacts.sort_by {|contact| contact.name}
      
      output << render_project_hierarchy(orphans)
      
      sorted.each do |contact|
        output << "<h3 class='contacts'>#{pretty_name(contact)}</h3>"
        output << render_project_hierarchy(contact.projects)
      end
      
    end
    @project = original_project
    output
  end
  
  def contact_select_tag(project)
    # retrieve the default contact
    contact_id = (params[:project] && params[:project][:contact_id]) || params[:contact_id]
    if contact_id
      selected = (contact_id.blank? ? nil : Contact.find(contact_id))
    else
      selected = project.contact_id
    end
    
    options = '<option value=""></option>'
    options << options_for_select(
      Contact.find(:all).sort!{|x, y| x.name <=> y.name }.collect {|m| [m.name, m.id]}, 
      :selected => selected,
      :required => false)
      
    content_tag('select', options, { :name => 'project[contact_id]', :id => 'project_contact_id' } )
  end
  
  def live_search_select_tag_options(array)
    options = "<option value=\"\" selected=\"selected\"></option>"
    options << options_for_select(array.collect { |r| [r.name, r.id] })
    options
  end

  def pretty_name(contact=@contact)
    
    result = "<div class=\"contact-name\">"
    
    if contact.is_company
      result << "<span class=\"contact-name-bold\">"
      result << contact.first_name
      result << "</span>"
    elsif !contact.last_name.blank?
      result << "<span class=\"contact-name-bold\">"
      result << contact.last_name
      result << ",</span> <span class=\"contact-name-normal\">"
      result << contact.first_name
      result << " " + contact.middle_name if contact.middle_name
      result << "</span>"
    else
      result << "<span class=\"contact-name-normal\">"
      result << contact.first_name
      result << " " + contact.middle_name if contact.middle_name
      result << "</span>"
    end   
    result << "</div>"
    
    result
  end

  # Display a link if the user is logged in
  def link_to_if_logged_in(name, options = {}, html_options = nil, *parameters_for_method_reference)
    link_to(name, options, html_options, *parameters_for_method_reference) if User.current.logged?
  end
  
  def link_to_remote_if_logged_in(name, options = {}, html_options = nil, *parameters_for_method_reference)
    link_to_remote(name, options, html_options, *parameters_for_method_reference) if User.current.logged?
  end

  def skype_to(skype_name, name = nil)
    return link_to(skype_name, 'skype:' + skype_name + '?call') unless skype_name.blank?
  end
  
  def contacts_paginator(paginator, page_options = {})
    pagination_links_each(paginator, page_options) do |link|
        options = { :url => {:controller => 'contacts',  :action => 'live_search', :search => '', :params => params.merge({:page => link})}, :update => 'contact_list' }
        html_options = { :href => url_for(:controller => 'contacts',  :action => 'live_search', :params => params.merge({:page => link})) }
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
    return link_to(contact.name, contact_url(contact))
  end

  def avatar_to(obj, options = { })  
    options[:size] = "64" unless options[:size]  
    options[:size] = options[:size] + "x" + options[:size] 
    options[:class] = "gravatar"  
    
    avatar = obj.attachments.find_by_description 'avatar'
    if avatar # and obj.visible?
      image_url = url_for :only_path => false, :controller => 'attachments', :action => 'download', :id => avatar, :filename => avatar.filename
      # image_url = url_for :only_path => false, :controller => 'contacts', :action => 'download_avatar', :id => obj, :filename => avatar.filename
      return image_tag(image_url, options)
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
  
  def tag_css_class(tag)
    tag_name = tag.name.gsub(/\s/, '-').downcase
    tag_name = tag_name.gsub(/[^_0-9a-z-]/, '')
    tag_class = tag.class == ActsAsTaggableOn::Tag ? '' : tag.class.to_s.downcase + ' '
    tag_class + tag_name
  end
  
end

class ContactsController < ApplicationController
  unloadable    
  
  Mime::Type.register "text/x-vcard", :vcf     
  
  default_search_scope :contacts    
  
  before_filter :authorize_global, :except => [:contacts_notes, :contacts_issues, :close_issue, :assigned_to_users]
  before_filter :find_contact, :except => [:index, :new, :create, :live_search, :contacts_notes, :close_issue, :contacts_issues, :destroy_note, :add_contact_to_issue, :filter]
 
  helper :attachments
  helper :contacts
  helper :watchers
  
  include AttachmentsHelper
  include WatchersHelper
  
  def show
    
    @attachments = @contact.attachments.find(:all, :order => "created_on DESC")
    @filter_tags = []
    
    
    if @contact.is_company 
      find_employees
      @notes_pages, @notes = paginate :notes,
                                      :per_page => 30,
                                      :conditions => {:source_id  => Contact.find_all_by_company(@contact.first_name, :order => "last_name, first_name").map(&:id) << @contact.id,  
                                                     :source_type => 'Contact'},
                                      :order => "created_on DESC" 
    else
      find_company
      @notes_pages = Paginator.new self, Note.count, 30, params[:page]

      @notes = @contact.notes.find(:all, :order => "created_on DESC")
      
    end  
    respond_to do |format|
      format.js if request.xhr?
      format.html {}
      format.vcf do              
        if Gem.available?('vpim') 
          require 'vpim/vcard'   
          export_to_vcard(@contact) 
        end  
      end
    end
  end
  
  def index
    @departments = Department.find(:all)
    @relationships = Relationship.find(:all)
    find_contacts
    
    if !request.xhr?
      last_notes
      find_tags
      # XXX: refactor index
      @other_tags = @tags
      @filter_tags = []
    end
    
    @contacts.sort! {|x, y| x.name <=> y.name }
    # debugger
    if request.xhr?
      render :partial => "list", :layout => false, :locals => {:contacts => @contacts} 
    end
    
    #@contacts = Contact.find(:all)
  end
  
  def filter
    
    @filter_relationships = []
    @filter_departments = []
    @filter_tags = []

    params[:filters].each do |tag|
      if Department.find_by_name(tag)
        @filter_departments << Department.find_by_name(tag)
      elsif Relationship.find_by_name(tag)
        @filter_relationships << Relationship.find_by_name(tag)
      elsif Tag.find_by_name(tag)
        @filter_tags << Tag.find_by_name(tag)
      else
        flash[:error] = t(:notice_tag_not_found, :tag => tag)
      end
    end
    
    @all_filters = @filter_relationships + @filter_departments + @filter_tags
    
    @contacts = Contact.by_last_name
    if @filter_relationships.any?
      @contacts = @contacts.with_relationship(@filter_relationships)
    end
    
    if @filter_departments.any?
      @contacts = @contacts.with_department(@filter_departments)
    end
    
    if @filter_tags.any?
      @contacts = @contacts.tagged_with(@filter_tags.map(&:name))
    end
        
    @contacts_pages = Paginator.new self, @contacts.size, 20, params[:page]
          
    @contacts = @contacts.find(:all, 
        :limit => @contacts_pages.items_per_page,
        :offset =>  @contacts_pages.current.offset) || []             
    
    @last_notes = Note.recent_notes(@contacts)
    @all_tags = Contact.tag_counts
    @other_tags = @all_tags - @filter_tags #.delete_if { |tag| @filter_tags.include? tag.name }
    @other_departments = Department.all - @filter_departments
    @other_relationships = Relationship.all - @filter_relationships
    
    if request.xhr?
      render :partial => "list", :layout => false, :locals => {:contacts => @contacts} 
    end
  end
  
  def edit
    #@contact = Contact.find_by_id(params[:id])
    @departments = Department.find(:all)
    @relationships = Relationship.find(:all)
  end

  def update
    #@contact = Contact.find_by_id(params[:id])  
    @departments = Department.find(:all)
    @relationships = Relationship.find(:all)
    # debugger
    if @contact.update_attributes(params[:contact])
      flash[:notice] = l(:notice_successful_update)     
      # debugger
      avatar = @contact.attachments.find_by_description 'avatar' 
      if params[:avatar]    
        avatar.destroy if avatar        
        Attachment.attach_files(@contact, params[:avatar])     
      end
      redirect_to :action => "show", :id => @contact
    else
      render "edit", :id => @contact  
    end
  end

  def destroy
    #@contact = Contact.find_by_id(params[:id])
    if @contact.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
    redirect_to :action => "index"
  end
  
  def new
    @contact = Contact.new
    @departments = Department.find(:all)
    @relationships = Relationship.find(:all)
  end

  def create
    @contact = Contact.new(params[:contact])
    @contact.author = User.current
    @departments = Department.find(:all)
    @relationships = Relationship.find(:all)
    if @contact.save
      flash[:notice] = l(:notice_successful_create)
      if params[:avatar]    
        Attachment.attach_files(@contact, params[:avatar]) 
      end
      
      redirect_to :action => "show", :id => @contact
    else
      render "new", :id => @contact
    end
  end

 
  def edit_tags
    @contact.tag_list = params[:contact][:tag_list]
    if @contact.save_tags
      flash[:notice] = l(:notice_tag_update_successful)
    else
      flash[:notice] = l(:notice_tag_update_failed)
    end

    respond_to do |format|
      format.js if request.xhr?
      format.html {redirect_to :action => 'show', :id => @contact }
    end
  end
  
  def add_task
    find_optional_project
    
    issue = Issue.new
    issue.subject = params[:task_subject]
    issue.project = @project if @project
    issue.tracker_id = params[:task_tracker]
    issue.author = User.current
    issue.due_date = params[:due_date]
    issue.assigned_to_id = params[:assigned_to]
    issue.description = params[:task_description]
    issue.status = IssueStatus.default
    if issue.save
      flash[:notice] = l(:notice_successful_add)
      @contact.issues << issue
      @contact.save
      redirect_to :action => 'show', :id =>  params[:id]
      return
    else
      redirect_to :action => 'show', :id =>  params[:id]
    end           
  end   
  
  def add_contact_to_issue 
    @issue = Issue.find(params[:issue_id])     
    @show_form = "true"
    if params[:id] then    
      find_contact
      @contact.issues << @issue
      @contact.save if request.post?   
    end
    respond_to do |format|
      format.html { redirect_to :back }  
      # format.html { redirect_to :controller => 'issues', :action => 'show', :id => params[:issue_id] }     
      format.js do
        render :update do |page|   
          page.replace_html 'issue_contacts', :partial => 'issues/contacts'
        end
      end
    end

  end
  
  def destroy_contact_from_issue    
    @issue = Issue.find(params[:issue_id])   
    @issue.contacts.delete(@contact)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'issue_contacts', :partial => 'issues/contacts'
        end
      end
    end    
  end
  
    
  def add_note
    @note = Note.new(params[:note])
    @note.author = User.current   
    @note.created_on = @note.created_on + Time.now.hour.hours + Time.now.min.minutes + Time.now.sec.seconds if @note.created_on
    if @contact.notes << @note
      
      if Redmine::VERSION.to_s >= "1.0.0"
        Attachment.attach_files(@note, params[:note_attachments])    
      else                                                                 
        attach_files(@note, params[:note_attachments])
      end
      
      flash[:notice] = l(:label_note_added)
      respond_to do |format|
        format.js do 
          render :update do |page|   
            page[:add_note_form].reset
            page.insert_html :top, "notes", :partial => 'notes/note_item', :object => @note, :locals => {:show_info => @contact.is_company, :note_source => @contact}
            page["note_#{@note.id}"].visual_effect :highlight    
            flash.discard   
          end
        end if request.xhr?       
        format.html {redirect_to :action => 'show', :id => @contact }
      end
    else
        # TODO При render если коммент не добавился то тут появялется ошибка из-за того что не передаются данные для paginate
      redirect_to :action => 'show', :id => @contact 
    end                   
  end

  def destroy_note   
    @note = Note.find(params[:note_id])
    @contact = @note.source
    @note.destroy
    respond_to do |format|
      format.js do 
        render :update do |page|  
            page["note_#{params[:note_id]}"].visual_effect :fade 
        end
      end if request.xhr?       
      format.html {redirect_to :action => 'show'}
    end
    
  end
      
  def close_issue
    issue = Issue.find(params[:issue_id])
    issue.status = IssueStatus.find(:first, :conditions =>  { :is_closed => true })    
    issue.save
    respond_to do |format|
      format.js do 
        render :update do |page|  
            page["issue_#{params[:issue_id]}"].visual_effect :fade 
        end
      end     
      format.html {redirect_to :back }
    end
    
  end     
  
  def contacts_notes  
    unless request.xhr?  
      find_tags
    end  
    # @notes = Comment.find(:all, 
    #                            :conditions => { :commented_type => "Contact", :commented_id => find_contacts.map(&:id)}, 
    #                            :order => "updated_on DESC")  
   cond = "(1 = 1) " 
   cond << " and ((#{Note.table_name}.source_type = 'Contact') and (#{Note.table_name}.source_id in (#{find_contacts(false).any? ? @contacts.map(&:id).join(', ') : 'NULL'}))"
   cond << " or (#{Note.table_name}.source_type = 'Deal') and (#{Note.table_name}.source_id in (#{find_deals.any? ? @deals.map(&:id).join(', ') : 'NULL'})))"    
   
   if params[:search_note] and request.xhr?   
        cond << " and (#{Note.table_name}.content LIKE '%#{params[:search_note]}%')" 
   end
    @notes_pages, @notes = paginate :notes,
                                    :per_page => 20,       
                                    :conditions => cond, 
                                    :order => "created_on DESC"   
    @notes.compact!   
    
    if request.xhr?
      render :partial => "notes/notes_list", :layout => false, :locals => {:notes => @notes, :notes_pages => @notes_pages} 
    end
                                                         
  end
             
  def contacts_issues   
    cond = "(1=1)"
    # cond = "issues.assigned_to_id = #{User.current.id}"
    cond << " and issues.project_id = #{@project.id}" if @project      
    cond << " and (issues.assigned_to_id = #{params[:assigned_to]})" unless params[:assigned_to].blank?
    
    @contacts_issues = Issue.visible.find(:all, 
                                          :joins => "INNER JOIN contacts_issues ON issues.id = contacts_issues.issue_id", 
                                          :group => :issue_id,
                                          :conditions => cond,
                                          :order => "issues.due_date")    
    assigned_to_users                                      
  end 
  
private
  
  def export_to_vcard(contact)
    card = Vpim::Vcard::Maker.make2 do |maker|

      maker.add_name do |name|
        name.prefix = ''
        name.given = contact.first_name
        name.family = contact.last_name
        name.additional = contact.middle_name
      end

      maker.add_addr do |addr|
        addr.preferred = true
        addr.street = contact.address
      end
      
      maker.title = contact.job_title
      maker.org = contact.company
      
      maker.add_note(contact.background)   
      
       
      maker.add_url(contact.website)

      contact.phones.each { |phone| maker.add_tel(phone) }
      contact.emails.each { |email| maker.add_email(email) }
    end   
    avatar = contact.attachments.find_by_description('avatar')  
    card = card.encode.sub("END:VCARD", "PHOTO;BASE64:" + "\n " + [File.open(avatar.diskfile).read].pack('m').to_s.gsub(/[ \n]/, '').scan(/.{1,76}/).join("\n ") + "\nEND:VCARD") if avatar && avatar.readable?

    send_data card.to_s.gsub('\n', ''), :filename => "contact.vcf", :type => 'text/x-vcard;', :disposition => 'attachment'	

  end
  


  def last_notes(count=5)
    @last_notes = Note.find(:all, 
                                 :conditions => { :source_type => "Contact", :source_id => @contacts.map(&:id)}, 
                                 :limit => count,
                                 :order => "created_on DESC").collect{|obj| obj if obj.source.visible?}.compact                 
  end
  
  def populate_project_id
    @contact = Contact.find(params[:id])
  end
  
  def find_project
    @project = Project.find(params[:project_id])
    
  # rescue ActiveRecord::RecordNotFound
  #   render_404
  end

  def find_contact
    @contact = Contact.find(params[:id])
  # rescue ActiveRecord::RecordNotFound
  #   render_404
  end
  
  def find_tags
    @tags = Contact.tag_counts
  end
  
  def find_employees
    @employees = Contact.find_all_by_company(@contact.first_name, :order => "last_name, first_name")
  end

  def find_company
    @company = Contact.find_by_first_name(@contact.company)
  end
  
  def find_deals           
    cond = "1 = 1"
    cond << " and #{Deal.table_name}.project_id = #{@project.id}" if @project  
    if params[:search] and request.xhr?   
      cond << " and (#{Deal.table_name}.name LIKE '%#{params[:search]}%')" 
    end        
    
    if params[:tag]
      #cond = "(1 = 0)"
    end
    @deals = Deal.find(:all, :conditions => cond) || []
  end
  
  def find_contacts(pages=true)
    # TODO: make this readable
    cond = "1 AND 1"          
    if params[:tag]
      @tag = Tag.find_by_name(params[:tag])
      if @tag     
        if pages
          @contacts_pages = Paginator.new self, Contact.tagged_with(@tag, :match_all => :true).count, 20, params[:page]     
          @contacts = Contact.tagged_with(@tag, :order => "last_name, first_name",
                                         :limit  =>  @contacts_pages.items_per_page,
                                         :offset =>  @contacts_pages.current.offset) || []
        else
          @contacts = Contact.tagged_with(@tag, :order => "last_name, first_name") || []
        end
      else
        @contacts = []
      end
    else      
      if params[:search] and not params[:search].empty? and request.xhr?   
        cond << " and (first_name LIKE '%#{params[:search]}%' or last_name LIKE '%#{params[:search]}%' or middle_name LIKE '%#{params[:search]}%' or company LIKE '%#{params[:search]}%' or job_title LIKE '%#{params[:search]}%')" 
      end
      if params[:relationship] and not params[:relationship].empty? and request.xhr?   
        cond << " AND id IN (SELECT contact_id FROM rc_contacts_relationships WHERE relationship_id = #{params[:relationship]})" 
      end
      if params[:department] and not params[:department].empty? and request.xhr?   
        cond << " AND id IN (SELECT contact_id FROM rc_contacts_departments WHERE department_id = #{params[:department]})" 
      end
      if pages  
        @contacts_pages = Paginator.new self, Contact.count(:conditions => cond), 20, params[:page]     
        @contacts = Contact.find(:all, :conditions => cond, :order => "last_name, first_name",
                                  :limit  =>  @contacts_pages.items_per_page,
                                  :offset =>  @contacts_pages.current.offset) || []   
      else     
        @contacts = Contact.find(:all, :conditions => cond, :order => "last_name, first_name") || []
      end
    end  
  end     
  
  def assigned_to_users
    user_values = []  
    user_values << ["<< #{l(:label_all)} >>", ""]
    user_values << ["<< #{l(:label_me)} >>", User.current.id] if User.current.logged?
    if @project
      user_values += @project.users.sort.collect{|s| [s.name, s.id.to_s] }
    else
      project_ids = Project.all(:conditions => Project.visible_by(User.current)).collect(&:id)
      if project_ids.any?
        # members of the user's projects
        user_values += User.active.find(:all, :conditions => ["#{User.table_name}.id IN (SELECT DISTINCT user_id FROM members WHERE project_id IN (?))", project_ids]).sort.collect{|s| [s.name, s.id.to_s] }
      end
    end    
  end
  
  def find_optional_project
    return true unless params[:project_id]
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  private
  
end

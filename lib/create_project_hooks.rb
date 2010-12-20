module RedmineContracts
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_projects_form, :partial => 'projects/contact'
  end
end
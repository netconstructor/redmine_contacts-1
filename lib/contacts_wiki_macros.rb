Redmine::WikiFormatting::Macros.register do
  desc "Contact Description Macro" 
  macro :Contact do |obj, args|
    args, options = extract_macro_options(args, :parent)
    raise 'No or bad arguments.' if args.size != 1
    contact = Contact.find(args.first)
    contact.name
  end
end 

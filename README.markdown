# Contacts plugin #

## Acknowledgements ##
This plugin was originally created by Kirill Bezrukov.  [The original version](http://www.redmine.org/boards/3/topics/19392?r=19450).

## Modifications ##
*	Changed tags to use acts_as_taggable for better compatibility.
*	Contacts are now global, and projects belong to a contact

## Install ##

	git clone git://github.com/cole/redmine_contacts.git vendor/plugin/redmine_contacts
	rake db:migrate_plugins RAILS_ENV=production

## Uninstall ##

	rake db:migrate:plugin NAME=redmine_contacts VERSION=0 RAILS_ENV=production 
	rm -r vendor/plugins/redmine_contacts

## Todos and known issues ##

*	Avatars are broken
*	Deals are broken
*	Add unit tests
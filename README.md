# redmine-cli
### A command line interface for redmine
Because using the browser is overrated.
[![Gem Version](https://badge.fury.io/rb/redmine-cli.png)](http://badge.fury.io/rb/redmine-cli)

## Installation
You first need to have Ruby with RubyGems.

Then run:

    gem install redmine-cli
    redmine install

This will create a .redmine file in your home directory. The file is a yaml file which contains our necessary configuration

During install, you can select the fields that you wish to be displayed, or accept the default (url, status, subject). This list can contain custom fields.

Note that previous versions of redmine-cli installed a version of .redmine that do not take full advantage of new features. For compatiblity purposes, this version is compatible with older .redmine files. However, for best results, you should re-run "redmine install" every time you upgrade the gem.

## Usage
You can get help by simpling executing:

    redmine

Listing tickets

    redmine list
    redmine list -a me -T bug

Display ticket

    redmine show 524

Updating a ticket

    redmine update 524 -description "New description"
    redmine update 256 --assigned_to me

Updating multiple tickets

    redmine update 2 3 4 --assigned_to johndoe

Updating all tickets for a list

    redmine list --status new --std_output | xargs redmine update --asigned_to me --status 3 -l

(Note that the last argument of the update command must be -l)

Interactively editing a ticket's fields

    redmine edit --description 2

Your editor will pop up, and you can modify the field. The ticket will be updated when you save the file and exit the editor.

## Configuration
Redmine-cli will install a default configuration file. However you can edit it to fit your redmine installation. 
You can add mappings for users, statuses, custom queries, and trackers like:

    user_mappings:
      "me": 1
      "johndoe": 24
    status_mappings:
      "new": 1
      "closed": 4
    tracker_mappings:
      "bug" : 1
      "feature" : 2

This will allow to use those names with the commands instead of the ids your redmine installation uses.

Additionally, you can choose which fields are displayed when you use "redmine list" by editing the list_fields section like:
    list_fields:
      - project
      - id
      - tracker
      - status
      - priority
      - assigned_to
      - subject
      - updated_on

You can choose from any of these fields:

* url - A "clickable" link to the issue
* id  - The ID number of the issue
* subject
* status - Open, Closed, Resolved, etc.
* start_date
* estimated_hours
* tracker - Bug, Feature, Improvement, etc.
* priority - Low, High, Immediate, etc. (Note: this field is colorized on terminals that support it)
* description
* assigned_to
* project
* author
* done_ratio
* due_date
* created_on
* updated_on

In addition to these fields, you can also specify any custom fields that you've configured in your Redmine site. If a field is not found on an issue, or the value is blank, then a blank value will be displayed in the list.

## Known Issues

If you use a non-administrative account, redmine-cli's mapping cache will not be able to retrieve the list of users (you must manually populate the user mappings in this case). Additionally, you'll receive an error like this whenever you try to update an issue:

    Updating mapping cache...
    Failed to fetch users: Failed.  Response code = 403.  Response message = Forbidden.

If this happens, you can disable the caching feature by setting "disable_caching": true in ~/.redmine

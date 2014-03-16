# redmine-cli
### A command line interface for redmine
Because using the browser is overrated.

## Installation
You first need to have Ruby with RubyGems.

Then run:

    gem install redmine-cli
    redmine install

  This will create a .redmine file in your home directory. The file is a yaml file which contains our necessary configuration

  During install, you can select the fields that you wish to be displayed, or accept the default (url, status, subject). This list can contain custom

## Configuration
  Redmine-cli will install a default configuration file. However you can edit it to fit your redmine installation. 
  You can add mappings for users, statuses and trackers like:

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
    \# Note that the last argument of the update command must be -l

  Interactively editing a ticket's fields

    redmine edit --description 2
    \# Your editor will pop up, and you can modify the field. The ticket will be updated when you save the file and exit the editor.

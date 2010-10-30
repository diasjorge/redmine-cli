# A command line interface for redmine

## Install

  Execute
      redmine install

  This will create a .redmine file in your home directory. The file is a yaml file which contains our necessary configuration

  Here you can add mappings for users and status like:

      user_mappings:
        "me": 1
        "johndoe": 24
      status_mappings:
        "new": 1
        "closed": 4

  This will allow to use those names with the commands instead of the ids of users or status

## Use cases

- Listing tickets

    redmine list
    redmine list -a me

- Display ticket

    redmine show 524

- Updating a ticket

    redmine update 524 -description "New description"
    redmine update 256 --assigned_to me

- Updating multiple tickets

    redmine update 2,3,4 --assigned_to johndoe

- Updating all tickets for a list

    redmine list --status new --std_output | xargs redmine update --asigned_to me --status 3 -l
    \# Note that the last argument of the update command must be -l

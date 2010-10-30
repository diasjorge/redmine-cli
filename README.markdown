# A command line interface for redmine

## Use cases

    redmine list
    redmine list -a
    redmine show 524
    redmine update 524 -d "New description"
    redmine update 256 --assigned_to "me"
    redmine update 2,3,4 --assigned_to "me"
    redmine list --status 1 | xargs redmine update --asigned_to "me" --status 3 -l
Feature: Install configuration file
  In order to use the command line interface
  Users need to be able to setup their config file

  @announce
  Scenario: Generate config file
    When I run "redmine install example.com user --test" interactively
     And I type "pass"

    Then the output should match /create.*\.redmine/
     And the following files should exist:
      | .redmine  |
     And the file ".redmine" should contain:
      """
      url: "http://example.com"
      username: "user"
      password: "pass"
      default_project_id: 1
      user_mappings:
        "admin": 1
      status_mappings:
        "new": 1
        "in-progress": 2
        "resolved": 3
        "feedback": 4
        "closed": 5
        "rejected": 6
      """

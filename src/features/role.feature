Feature: Manage Roles
  In order to manage roles
  As an admin
  I want to add/edit/remove roles

  Background:
    Given I am an authorised user
    And I am logged in
    Given there's a list of roles
    And a role "Captain" exists
    And I am using new UI

  Scenario: Change the name
    Given I am on the admin roles page
    And there should be a role named "Captain"
    When I follow "Captain"
    And I follow "Edit"
    Then I should see "Editing Role:"
    When I fill in "role[name]" with "Admiral"
    And I press "Save"
    Then I should see "Role updated successfully!"

  Scenario: Show role details
    Given a role "Admiral" exists
    And I am on the admin roles page
    When I follow "Admiral"
    Then I should be on Admiral's role page

  Scenario: Show default role privileges
    Given I am on the admin roles page
    And there should be a role named "Administrator"
    When I follow "Administrator"
    Then I should be on Administrator's role page

  Scenario: Delete roles
    Given a role "Admiral" exists
    And I am on the admin roles page
    And there are 2 more roles
    When I check "Admiral" role
    And I check "Captain" role
    And I press "Destroy"
    Then there should be 0 more roles
    And I should be on the admin roles page
    And I should not see "Captain"
    And I should not see "Admiral"

  Scenario: Search roles
    Given a role "Admiral" exists
    And I am on the admin roles page
    And there are 2 more roles
    When I fill in "q" with "admi"
    And I press "Search"
    Then I should see "Admiral"
    And I should not see "Captain"
    When I fill in "q" with "Captain"
    And I press "Search"
    Then I should not see "Admiral"
    And I should see "Captain"
    When I fill in "q" with ""
    And I press "Search"
    Then I should see "Admiral"
    And I should see "Captain"

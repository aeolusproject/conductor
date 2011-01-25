Feature: Manage Roles
  In order to manage roles
  As an admin
  I want to add/edit/remove roles

  Background:
    Given I am an authorised user
    And I am logged in
    And there's no role
    And a role "Captan" exists
    And I am using new UI

  Scenario: Change the name
    Given I am on the admin roles page
    And there is a role "Captan"
    When I follow "Captan"
    And I follow "Edit"
    Then I should see "Editing Role:"
    When I fill in "role[name]" with "Admiral"
    And I press "Save"
    Then I should see "Role updated successfully!"

  Scenario: Show role detials
    Given a role "Admiral" exists
    And I am on the admin roles page
    When I follow "Admiral"
    Then I should be on Admiral's role page

  Scenario: Delete roles
    Given a role "Admiral" exists
    And I am on the admin roles page
    And there are 2 roles
    When I check "Admiral" role
    And I check "Captan" role
    And I press "Destroy"
    Then there should only be 0 roles
    And I should be on the admin roles page
    And I should not see "Captan"
    And I should not see "Admiral"

  Scenario: Search roles
    Given a role "Admiral" exists
    And I am on the admin roles page
    And there are 2 roles
    When I fill in "q" with "admi"
    And I press "Search"
    Then I should see "Admiral"
    And I should not see "Captan"
    When I fill in "q" with "Captan"
    And I press "Search"
    Then I should not see "Admiral"
    And I should see "Captan"
    When I fill in "q" with ""
    And I press "Search"
    Then I should see "Admiral"
    And I should see "Captan"

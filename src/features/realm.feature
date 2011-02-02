Feature: Manage Realms
  In order to manage realms
  As an admin
  I want to add/edit/remove realms

  Background:
    Given I am an authorised user
    And I am logged in
    And there's no realm
    And a realm "testrealm1" exists

  Scenario: Create new frontend realm
    Given I am on the admin realms page
    When I follow "Create"
    Then I should see "Create a new Realm"
    When I fill in "frontend_realm[name]" with "testrealm2"
    And I press "Save"
    Then I should see "Realm was added."

  Scenario: Add realm mapping
    Given I am on the admin realms page
    And there is a realm "testrealm1"
    And a provider "provider1" exists
    When I follow "testrealm1"
    And I follow "Mapping"
    And I follow "Add mapping to provider"
    Then I should see "Create a new Realm Mapping"
    When I press "Save"
    Then I should see "Realm mapping was added."

  Scenario: Change the name
    Given I am on the admin realms page
    And there is a realm "testrealm1"
    When I follow "testrealm1"
    And I follow "Edit"
    Then I should see "Editing Realm:"
    When I fill in "frontend_realm[name]" with "testrealm2"
    And I press "Save"
    Then I should see "Realm updated successfully!"

  Scenario: Show realm detials
    Given a realm "testrealm2" exists
    And I am on the admin realms page
    When I follow "testrealm2"
    Then I should be on testrealm2's realm page

  Scenario: Delete realms
    Given a realm "testrealm2" exists
    And I am on the admin realms page
    And there are 2 realms
    When I check "testrealm2" realm
    And I check "testrealm1" realm
    And I press "Delete"
    Then there should be only 0 realms
    And I should be on the admin realms page
    And I should not see "testrealm1"
    And I should not see "testrealm2"

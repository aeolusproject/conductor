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
    Given I am on the realms page
    When I follow "new_realm_button"
    Then I should see "Create a new Realm"
    When I fill in "frontend_realm_name" with "testrealm2"
    And I press "Save"
    Then I should see "Realm was added."

  Scenario: Validate unique frontend realm name
    Given I am on the realms page
    And there is a realm "testrealm1"
    When I follow "new_realm_button"
    Then I should see "Create a new Realm"
    When I fill in "frontend_realm_name" with "testrealm1"
    And I press "frontend_realm_submit"
    Then I should see "Name has already been taken"

  Scenario: Add realm mapping
    Given I am on the realms page
    And there is a realm "testrealm1"
    And a provider "provider1" exists
    When I follow "testrealm1"
    And I follow "mapping_to_provider_button"
    Then I should see "Create a new Realm Mapping"
    When I press "realm_backend_target_submit"
    Then I should see "Realm mapping was added."

  Scenario: Add a realm mapping w/o selecting backend target
    Given I am on the realms page
    And there is a realm "testrealm1"
    And there is no provider
    When I follow "testrealm1"
    And I follow "mapping_to_provider_button"
    Then I should see "Create a new Realm Mapping"
    And I press "realm_backend_target_submit"
    Then I should see "Realm or provider can't be blank"

  Scenario: Change the name
    Given I am on the realms page
    And there is a realm "testrealm1"
    When I follow "testrealm1"
    And I follow "edit_realm_button"
    Then I should see "Properties"
    When I fill in "frontend_realm_name" with "testrealm2"
    And I press "frontend_realm_submit"
    Then I should see "Realm updated successfully!"

  Scenario: Show realm detials
    Given a realm "testrealm2" exists
    And I am on the realms page
    When I follow "testrealm2"
    Then I should be on testrealm2's realm page

  Scenario: Delete realms
    Given a realm "testrealm2" exists
    And I am on the realms page
    And there are 2 realms
    When I check "testrealm2" realm
    And I check "testrealm1" realm
    And I press "delete_button"
    Then there should be only 0 realms
    And I should be on the realms page
    And I should see "These Realms were deleted: testrealm1, testrealm2"

  Scenario: Delete realm without selecting one
    Given I am on the realms page
    When I press "delete_button"
    Then I should be on the realms page
    And I should see "You must select at least one realm to delete."

  Scenario: Delete realm mapping without selecting one
    Given I am on the realms page
    And there is a realm "testrealm1"
    When I follow "testrealm1"
    And I press "delete_button"
    Then I should see "You must select at least one mapping to delete"

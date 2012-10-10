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
    Then I should be on the new realm page
    When I fill in "frontend_realm_name" with "testrealm2"
    And I press "Save"
    Then I should see a confirmation message

  Scenario: Validate unique frontend realm name
    Given I am on the realms page
    And there is a realm "testrealm1"
    When I follow "new_realm_button"
    Then I should be on the new realm page
    When I fill in "frontend_realm_name" with "testrealm1"
    And I press "frontend_realm_submit"
    Then I should see an error message

  Scenario: Add realm mapping
    Given I am on the realms page
    And there is a realm "testrealm1"
    And a provider "mock_provider1" exists
    When I follow "testrealm1"
    And I follow "mapping_to_provider_button"
    Then I should be on the new realm mapping page
    When I press "realm_backend_target_submit"
    Then I should see a confirmation message

  Scenario: Change the name
    Given I am on the realms page
    And there is a realm "testrealm1"
    When I follow "testrealm1"
    And I follow "edit_realm_button"
    Then I should see "Properties"
    When I fill in "frontend_realm_name" with "testrealm2"
    And I press "frontend_realm_submit"
    Then I should see a confirmation message

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
    And I should see a confirmation message

  Scenario: Delete realm without selecting one
    Given I am on the realms page
    When I press "delete_button"
    Then I should be on the realms page
    And I should see an error message

  Scenario: Delete realm mapping without selecting one
    Given a realm "testrealm1" exists mapped to a provider "mock_provider1"
    And I am on the realms page
    When I follow "testrealm1"
    And I press "delete_mapping_button"
    Then I should see an error message

  Scenario: Search Realms
    Given a realm "myrealm" exists
    And a realm "somerealm" exists
    And I am on the realms page
    Then I should see "myrealm"
    And I should see "somerealm"
    When I fill in "realms_search" with "some"
    And I press "apply_realms_search"
    Then I should see "somerealm"
    And I should not see "myrealm"
    When I fill in "realms_search" with "myrealm"
    And I press "apply_realms_search"
    Then I should see "myrealm"
    And I should not see "somerealm"

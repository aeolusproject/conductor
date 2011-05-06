Feature: Manage System wide Settings
  In order to manage my cloud engine
  As a user
  I want to manage system settings

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Change the self service default quota
    Given the default quota is set to 5
    And I am on the self service settings page
    When I fill in "self_service_default_quota[maximum_running_instances]" with "8"
    And I press "Save"
    Then I should see "Settings Updated!"
    And the default quota should be 8
    And I should be on the self service settings page

  Scenario: Invalid decimal entry for the self service default quota
    Given the default quota is set to 5
    And I am on the self service settings page
    When I fill in "self_service_default_quota[maximum_running_instances]" with "1.5"
    And I press "Save"
    Then I should see "Could not update the default quota"
    And the default quota should be 5
    And I should be on the settings update page

  Scenario: Invalid chars entry for the self service default quota
    Given the default quota is set to 5
    And I am on the self service settings page
    When I fill in "self_service_default_quota[maximum_running_instances]" with "abc"
    And I press "Save"
    Then I should see "Could not update the default quota"
    And the default quota should be 5
    And I should be on the settings update page

  Scenario: Invalid special chars entry for the self service default quota
    Given the default quota is set to 5
    And I am on the self service settings page
    When I fill in "self_service_default_quota[maximum_running_instances]" with "^&(*_!"
    And I press "Save"
    Then I should see "Could not update the default quota"
    And the default quota should be 5
    And I should be on the settings update page

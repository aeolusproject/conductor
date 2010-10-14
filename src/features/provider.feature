Feature: Manage Providers
  In order to manage my cloud infrastructure
  As a user
  I want to manage cloud providers

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List providers
    Given I am on the homepage
    And there are these providers:
    | name      |
    | provider1 |
    | provider2 |
    | provider3 |
    When I go to the providers page
    Then I should see the following:
    | provider1 |
    | provider2 |
    | provider3 |

  Scenario: Show provider details
    Given there is a provider named "testprovider"
    And I am on the providers page
    When I follow "testprovider"
    Then I should see "Provider Name"
    And I should see "Provider URL"

  Scenario: Create a new Provider
    Given I am on the providers page
    And there is not a provider named "testprovider"
    When I press "Add"
    Then I should be on the new provider page
    When I fill in "provider[name]" with "testprovider"
    And I fill in "provider[url]" with "http://localhost:3001/api"
    And I press "add_provider"
    Then I should be on the show provider page
    And I should see "Provider added"
    And I should have a provider named "testprovider"

  Scenario: Test Provider Connection Successful
    Given I am on the providers page
    When I press "Add"
    Then I should be on the new provider page
    When I fill in "provider[name]" with "testprovider"
    And I fill in "provider[url]" with "http://localhost:3001/api"
    And I press "test_connection"
    Then I should see "Successfuly Connected to Provider"

  Scenario: Test Provider Connection Failure
    Given I am on the providers page
    When I press "Add"
    Then I should be on the new provider page
    When I fill in "provider[name]" with "incorrect_provider"
    And I fill in "provider[url]" with "http://incorrecthost:3001/api"
    And I press "test_connection"
    Then I should see "Failed to Connect to Provider"

  Scenario: Test Account Connection Success
    Given I am on the homepage
    And there are these providers:
    | name      |
    | provider1 |
    When I go to the providers page
    And I follow "provider1"
    And I follow "Provider Accounts"
    And I fill in "cloud_account[label]" with "MockAccount"
    And I fill in "cloud_account[username]" with "mockuser"
    And I fill in "cloud_account[password]" with "mockpassword"
    And I fill in "cloud_account[account_number]" with "12345678"
    And I press "test_account"
    Then I should see "Test Connection Success: Valid Account Details"

  Scenario: Test Account Connection Failure
    Given I am on the homepage
    And there are these providers:
    | name      |
    | provider1 |
    When I go to the providers page
    And I follow "provider1"
    And I follow "Provider Accounts"
    And I fill in "cloud_account[label]" with "IncorrectAccount"
    And I fill in "cloud_account[username]" with "incorrect_user"
    And I fill in "cloud_account[password]" with "incorrect_password"
    And I fill in "cloud_account[account_number]" with "12345678"
    And I press "test_account"
    Then I should see "Test Connection Failed: Invalid Account Details"
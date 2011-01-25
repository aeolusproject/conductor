Feature: Manage Providers
  In order to manage my cloud infrastructure
  As a user
  I want to manage cloud providers

  Background:
    Given I am an authorised user
    And I am logged in
    And I am using new UI

  Scenario: List providers
    Given I am on the homepage
    And there are these providers:
    | name      |
    | provider1 |
    | provider2 |
    | provider3 |
    When I go to the admin providers page
    Then I should see the following:
    | provider1 |
    | provider2 |
    | provider3 |

  Scenario: Show provider details
    Given there is a provider named "testprovider"
    And I am on the admin providers page
    When I follow "testprovider"
    Then I should see "Provider name"
    And I should see "Provider URL"

  Scenario: Create a new Provider
    Given I am on the admin providers page
    And there is not a provider named "testprovider"
    When I follow "Create"
    Then I should be on the new admin provider page
    When I fill in "provider[name]" with "testprovider"
    And I fill in "provider[url]" with "http://localhost:3001/api"
    And I press "Save"
    Then I should be on the admin providers page
    And I should see "Provider added"
    And I should have a provider named "testprovider"

  Scenario: Test Provider Connection Successful
    Given I am on the admin providers page
    When I follow "Create"
    Then I should be on the new admin provider page
    When I fill in "provider[name]" with "testprovider"
    And I fill in "provider[url]" with "http://localhost:3001/api"
    And I press "test_connection"
    Then I should see "Successfuly Connected to Provider"

  Scenario: Test Provider Connection Failure
    Given I am on the admin providers page
    When I follow "Create"
    Then I should be on the new admin provider page
    When I fill in "provider[name]" with "incorrect_provider"
    And I fill in "provider[url]" with "http://incorrecthost:3001/api"
    And I press "test_connection"
    Then I should see "Failed to Connect to Provider"

  Scenario: Delete a provider
    Given I am on the homepage
    And there is a provider named "provider1"
    And this provider has 5 replicated images
    And this provider has 5 hardware profiles
    And this provider has a realm
    And this provider has a cloud account
    When I go to the admin providers page
    And I check "provider1" provider
    And I press "Delete"
    And there should not exist a provider named "provider1"
    And there should not be any replicated images
    And there should not be any hardware profiles
    And there should not be a cloud account
    And there should not be a realm

  Scenario: Search for hardware profiles
    Given there are these providers:
    | name          | url                         |
    | Test          | http://testprovider.com/api |
    | Mock          | http://mockprovider.com/api |
    | Other         | http://sometesturl.com/api  |
    And I am on the admin providers page
    Then I should see the following:
    | Test  | http://testprovider.com/api |
    | Mock  | http://mockprovider.com/ap  |
    | Other | http://sometesturl.com/api  |
    When I fill in "q" with "test"
    And I press "Search"
    Then I should see "Test"
    And I should see "Other"
    And I should not see "Mock"
    When I fill in "q" with "Mock"
    And I press "Search"
    Then I should see "Mock"
    And I should not see "Test"
    And I should not see "Other"
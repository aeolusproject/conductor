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
    And I should see "Test Connection"

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

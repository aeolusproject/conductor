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

  Scenario: List providers in XML format
    Given I accept XML
    And there are these providers:
    | name      |
    | provider1 |
    | provider2 |
    | provider3 |
    When I go to the providers page
    Then I should get a XML document
    And XML should contain 3 providers
    And each provider should have "name"
    And each provider should have "url"
    And each provider should have "provider_type"
    And there should be these provider:
    | name         | url                       | provider_type |
    | provider1    | http://localhost:3002/api | mock          |
    | provider2    | http://localhost:3002/api | mock          |
    | provider3    | http://localhost:3002/api | mock          |

  Scenario: Show provider details
    Given there is a provider named "testprovider"
    And I am on the providers page
    When I follow "testprovider"
    Then I should see "Provider name"
    And I should see "Provider URL"

  Scenario: Create a new Provider
    Given I am on the providers page
    And there is not a provider named "testprovider"
    When I follow "create_new_provider"
    Then I should be on the new provider page
    When I fill in "provider[name]" with "testprovider"
    And I fill in "provider[url]" with "http://localhost:3002/api"
    And I select "Amazon EC2" from "provider_provider_type_id"
    And I press "save"
    Then I should be on the testprovider's edit provider page
    And I should see "Provider added"
    And I should have a provider named "testprovider"

  Scenario: Create a new Provider failure when using wrong url
    Given I am on the providers page
    And there is not a provider named "testprovider"
    When I follow "New Provider"
    Then I should be on the new provider page
    When I fill in "provider[name]" with "testprovider"
    And I fill in "provider[url]" with "http://localhost:3010/api"
    And I select "Amazon EC2" from "provider_provider_type_id"
    And I press "save"
    Then I should be on the providers page
    And I should see "Failed to connect to Provider"

  Scenario: Delete a provider
    Given I am on the homepage
    And there is a provider named "provider1"
    And this provider has 5 hardware profiles
    And this provider has a realm
    And this provider has a provider account
    When I go to the provider1's edit provider page
    And I press "delete"
    And there should not exist a provider named "provider1"
    And there should not be any hardware profiles
    And there should not be a provider account
    And there should not be a realm

#  Scenario: Search for hardware profiles
#    Given there are these providers:
#    | name          | url                         |
#    | Test          | http://testprovider.com/api |
#    | Kenny         | http://mockprovider.com/api |
#    | Other         | http://sometesturl.com/api  |
#    And I am on the providers page
#    Then I should see the following:
#    | Test  | http://testprovider.com/api |
#    | Kenny | http://mockprovider.com/ap  |
#    | Other | http://sometesturl.com/api  |
#    When I fill in "q" with "test"
#    And I press "Search"
#    Then I should see "Test"
#    And I should see "Other"
#    And I should not see "Kenny"
#    When I fill in "q" with "Kenny"
#    And I press "Search"
#    Then I should see "Kenny"
#    And I should not see "Test"
#    And I should not see "Other"

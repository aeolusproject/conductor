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
    When I follow "Settings"
    Then I should see the following:
    | provider1 |
    | provider2 |
    | provider3 |

  Scenario: Show provider details
    Given there is a provider named "testprovider"
    And I am on the settings page
    When I follow "testprovider"
    Then I should see "Accounts"
    And I should see "Realms"
    And I should see "User access"
    And I should see "Settings"

  Scenario: Create a new Provider
	  Given I am on the settings page
	  And there is not a provider named "testprovider"
	  When I follow "Add a provider"
	  Then I should be on the new provider page
	  And I should see "Add a cloud provider"
	  When I fill in "provider[name]" with "testprovider"
	  And I fill in "provider[url]" with "http://localhost:3001/api"
	  And I press "Save"
	  Then I should be on the show provider page
	  And I should see "Provider added"
	  And I should have a provider named "testprovider"

  Scenario: Delete a provider
    Given there is a provider named "testprovider"
    And I am on the settings page
    Then I should see "testprovider"
    When I follow "testprovider"
    Then I should be on the show provider page
    When I follow provider settings link
    Then I should be on the provider settings page
    When I delete provider
    Then I should be on the providers page
    And I should see "Providers"
    And I should not see "testprovider"

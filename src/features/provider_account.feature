Feature: Manage Provider Accounts
  In order to manage my cloud infrastructure
  As a user
  I want to manage provider accounts

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List provider accounts
    Given I am on the homepage
    And there is a provider named "testprovider"
    When I go to the provider accounts page
    Then I should see "New Provider Account"
    And there should be no provider accounts

  Scenario: List providers in XML format
    Given I accept XML
    And there is ec2 provider account "ec2_account"
    And there is mock provider account "mock_account"
    When I go to the provider accounts page
    Then I should get a XML document
    And there should be these mock provider accounts:
    | name          | provider     | provider_type | username | password     |
    | mock_account  | mockprovider | mock          |||
    And there should be these ec2 provider accounts:
    | name         | provider   | provider_type | access_key | secret_access_key |
    | ec2_account  | ec2provider| ec2           |||

  Scenario: Create a new Provider Account
    Given there is a provider named "testprovider"
    And there are no provider accounts
    And I am on the provider accounts page
    When I follow "New Provider Account"
    Then I should be on the new provider account page
    And I should see "New Provider Account"
    When I select "testprovider" from "provider_account_provider_id"
    And I fill in "provider_account[label]" with "testaccount"
    And I fill in "provider_account[credentials_hash][username]" with "mockuser"
    And I fill in "provider_account[credentials_hash][password]" with "mockpassword"
    And I fill in "quota[maximum_running_instances]" with "13"
    And I press "Save"
    Then I should be on testaccount's provider account page
    And I should see "Account testaccount was added."
    And I should have a provider account named "testaccount"
    And I should see "Properties for testaccount"
    And I should see "Running instances quota: 13"

  Scenario: Create a new Provider Account using wrong credentials
    Given there is a provider named "testprovider"
    And there are no provider accounts
    And I am on the provider accounts page
    When I follow "New Provider Account"
    Then I should be on the new provider account page
    And I should see "New Provider Account"
    When I select "testprovider" from "provider_account_provider_id"
    And I fill in "provider_account[label]" with "testaccount"
    When I fill in "provider_account[credentials_hash][username]" with "mockuser"
    And I fill in "provider_account[credentials_hash][password]" with "wrongpassword"
    And I fill in "quota[maximum_running_instances]" with "13"
    And I press "Save"
    Then I should see "Credentials are invalid!"

  Scenario: Delete a provider account
    Given there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And the account has an instance associated with it
    And I am on the provider accounts page
    When I check the "testaccount" account
    And I press "Delete"
    Then I should be on the provider accounts page
    And I should see "was not deleted"
    And there should be 1 provider account
    When I delete all instances from the account
    And I check the "testaccount" account
    And I press "Delete"
    Then I should be on the provider accounts page
    And I should see "was deleted"
    And there should be no provider accounts

  Scenario: Edit a existing Provider Account
    Given there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And I am on the provider accounts page
    And I follow "testaccount"
    When I follow "Edit"
    And I fill in "provider_account[label]" with "testaccount_updated"
    And I press "Save"
    Then I should see "testaccount_updated"
    And I should see "Provider Account updated!" within ".flashes"

  Scenario: Edit a existing Provider Account with invalid credentials
    Given there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And I am on the provider accounts page
    And I follow "testaccount"
    When I follow "Edit"
    And I fill in "provider_account[label]" with ""
    And I press "Save"
    Then I should see "Provider Account wasn't updated!"

#  Scenario: Search for Provider Accounts
#    Given there is a provider named "testprovider"
#    And there is a provider account named "testaccount"
#    And there is a second provider account named "otheraccount"
#    And I am on the provider accounts page
#    When I fill in "q" with "test"
#    And I press "Search"
#    Then I should see the following:
#    | testaccount | mockuser |
#    And I should not see "otheraccount"
#    When I fill in "q" with "other"
#    And I press "Search"
#    Then I should see the following:
#    | otheraccount |
#    And I should not see "testaccount"

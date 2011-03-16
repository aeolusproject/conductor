Feature: Manage Provider Accounts
  In order to manage my cloud infrastructure
  As a user
  I want to manage provider accounts

  Background:
    Given I am an authorised user
    And I am logged in
    And There is a mock pulp repository

  Scenario: List provider accounts
    Given I am on the homepage
    And there is a provider named "testprovider"
    When I go to the admin provider accounts page
    Then I should see "New Account"
    And there should be no provider accounts

  Scenario: Create a new Provider Account
    Given there is a provider named "testprovider"
    And there are no provider accounts
    And I am on the admin provider accounts page
    When I follow "New Account"
    Then I should be on the new admin provider account page
    And I should see "New Account"
    When I select "testprovider" from "provider_account_provider_id"
    And I fill in "provider_account[label]" with "testaccount"
    And I fill in "provider_account[credentials_hash][username]" with "mockuser"
    And I fill in "provider_account[credentials_hash][password]" with "mockpassword"
    And I fill in "quota[maximum_running_instances]" with "13"
    And I press "Add"
    Then I should be on testaccount's provider account page
    And I should see "Provider account added"
    And I should have a provider account named "testaccount"
    And I should see "Properties for testaccount"
    And I should see "Running instances quota: 13"

  Scenario: Create a new Provider Account using wrong credentials
    Given there is a provider named "testprovider"
    And there are no provider accounts
    And I am on the admin provider accounts page
    When I follow "New Account"
    Then I should be on the new admin provider account page
    And I should see "New Account"
    When I select "testprovider" from "provider_account_provider_id"
    And I fill in "provider_account[label]" with "testaccount"
    When I fill in "provider_account[credentials_hash][username]" with "mockuser"
    And I fill in "provider_account[credentials_hash][password]" with "wrongpassword"
    And I fill in "quota[maximum_running_instances]" with "13"
    And I press "Add"
    Then I should see "Credentials are invalid!"

  Scenario: Delete a provider account
    Given there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And the account has an instance associated with it
    And I am on the admin provider accounts page
    When I check the "testaccount" account
    And I press "Delete"
    Then I should be on the admin provider accounts page
    And I should see "was not deleted"
    And there should be 1 provider account
    When I delete all instances from the account
    And I check the "testaccount" account
    And I press "Delete"
    Then I should be on the admin provider accounts page
    And I should see "was deleted"
    And there should be no provider accounts

  Scenario: Search for Provider Accounts
    Given there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And there is a second provider account named "otheraccount"
    And I am on the admin provider accounts page
    When I fill in "q" with "test"
    And I press "Search"
    Then I should see the following:
    | testaccount | mockuser |
    And I should not see "otheraccount"
    When I fill in "q" with "other"
    And I press "Search"
    Then I should see the following:
    | otheraccount |
    And I should not see "testaccount"

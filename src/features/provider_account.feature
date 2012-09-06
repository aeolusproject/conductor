Feature: Manage Provider Accounts
  In order to manage my cloud infrastructure
  As a user
  I want to manage provider accounts

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List provider accounts for provider
    Given I am on the homepage
    And there is a provider named "mockprovider"
    When I go to the mockprovider's provider accounts page
    Then I should see "New Account"
    And there should be no provider accounts

  Scenario: Create a new Provider Account
    Given there is a provider named "mockprovider"
    And there are no provider accounts
    And I am on the mockprovider's provider accounts page
    When I follow "New Account"
    Then I should be on mockprovider's new provider account page
    And I should see "New Provider Account"
    When I fill in "provider_account[label]" with "testaccount"
    And I fill in "provider_account[credentials_hash][username]" with "mockuser"
    And I fill in "provider_account[credentials_hash][password]" with "mockpassword"
    And I fill in "quota[maximum_running_instances]" with "13"
    And I press "Save"
    Then I should be on the mockprovider's edit provider page
    And I should see "Account testaccount was added."
    And I should have a provider account named "testaccount"

  Scenario: Create a new Provider Account using wrong credentials
    Given there is a provider named "mockprovider"
    And there are no provider accounts
    And I am on the mockprovider's provider accounts page
    And I follow "New Account"
    Then I should be on mockprovider's new provider account page
    And I should see "New Provider Account"
    And I fill in "provider_account[label]" with "testaccount"
    When I fill in "provider_account[credentials_hash][username]" with "mockuser"
    And I fill in "provider_account[credentials_hash][password]" with "wrongpassword"
    And I fill in "quota[maximum_running_instances]" with "13"
    And I press "Save"
    Then I should see "Cannot add the Provider Account."
    Then I should see "Login credentials are invalid for this Provider"

  Scenario: Delete a provider account
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And the account has an instance associated with it
    And I am on the mockprovider's provider accounts page
    When I check the "testaccount" account
    And I press "Delete"
    Then I should be on the mockprovider's edit provider page
    And I should see "was not deleted"
    And there should be 1 provider account
    When I delete all instances from the account
    And I check the "testaccount" account
    And I press "Delete"
    Then I should be on the mockprovider's edit provider page
    And I should see "was deleted"
    And there should be no provider accounts

  Scenario: Delete a provider account with stopped instances
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And the account has an instance associated with it
    And all the account instances are stopped
    And I am on the mockprovider's provider accounts page
    When I check the "testaccount" account
    And I press "Delete"
    Then I should be on the mockprovider's edit provider page
    And I should see "was deleted"
    And there should be no provider accounts

  Scenario: Edit a existing Provider Account
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And I am on the mockprovider's provider accounts page
    And I follow "testaccount"
    When I follow "Edit"
    And I fill in "provider_account[label]" with "testaccount_updated"
    And I press "Save"
    Then I should see "Provider Account updated" within ".flashes"

  Scenario: Edit a existing Provider Account with invalid credentials
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And I am on the mockprovider's provider accounts page
    And I follow "testaccount"
    When I follow "Edit"
    And I fill in "provider_account[label]" with ""
    And I press "Save"
    Then I should see "Provider Account wasn't updated"

  Scenario: Display alert when Provider Account Quota is over 70% filled
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And the account has an instance associated with it
    And I am on the mockprovider's provider accounts page
    When I follow "testaccount"
    And I follow "Edit"
    And I fill in "quota[maximum_running_instances]" with "1"
    And I press "save"
    Then I should be on the mockprovider's edit provider page
    And I should see "Account Quota Reached"

  Scenario: Display alert when Provider Account Quota is exceeded
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And the account has an instance associated with it
    And I am on the mockprovider's provider accounts page
    When I follow "testaccount"
    And I follow "Edit"
    And I fill in "quota[maximum_running_instances]" with "0"
    And I press "save"
    Then I should be on the mockprovider's edit provider page
    And I should see "Account Quota Exceeded"

  Scenario: Test Provider Account connection
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And I am on the mockprovider's provider accounts page
    When I follow "testaccount"
    Then I should see "Test Connection"
    When I follow "Test Connection"
    Then I should see "Test Connection Success"

  Scenario: Search for Provider Accounts
    Given there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And I am on the mockprovider's provider accounts page
    When I fill in "provider_accounts_search" with "abc"
    And I press "apply_provider_accounts_search"
    And I should not see "testaccount"

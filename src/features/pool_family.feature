Feature: Pool Families
  In order to manage my cloud infrastructure
  As a user
  I want to manage pool families

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List pool families
    Given I am on the homepage
    And there are these pool families:
    | name      |
    | pool_family1 |
    | pool_family2 |
    | pool_family3 |
    When I go to the pool families page
    Then I should see the following:
    | pool_family1 |
    | pool_family2 |
    | pool_family3 |

  Scenario: Show pool family details
    Given there is a pool family named "testpoolfamily"
    And I am on the pool families page
    When I follow "testpoolfamily"
    Then I should see "Properties for testpoolfamily"

  Scenario: Create a new Pool family
    Given I am on the pool families page
    And there is not a pool family named "testpoolfamily"
    When I follow "New Pool Family"
    Then I should be on the new pool family page
    When I fill in "pool_family[name]" with "testpoolfamily"
    When I fill in "pool_family[quota_attributes][maximum_running_instances]" with "2"
    And I press "Save"
    Then I should be on the pool families page
    And I should see "Pool family was added."
    And I should have a pool family named "testpoolfamily"

  Scenario: Delete a pool family
    Given I am on the homepage
    And there is a pool family named "poolfamily1"
    When I go to the pool families page
    And I check "poolfamily1" pool family
    And I press "Delete"
    Then there should not exist a pool family named "poolfamily1"

  Scenario: Disallow deletion of default pool family
    Given I am on the pool families page
    Then I should see "default"
    When I check "default" pool family
    And I press "Delete"
    Then I should see "Could not delete the following Pool Families: default."
    And I should see "default"

#  Scenario: Search for pool families
#    Given there are these pool families:
#    | name      |
#    | first_family |
#    | second_family |
#    | third_family |
#    Given I am on the pool families page
#    Then I should see "first_family"
#    And I should see "second_family"
#    And I should see "third_family"
#    When I fill in "q" with "second"
#    And I press "Search"
#    Then I should see "second_family"
#    And I should not see "first_family"
#    And I should not see "third_family"
#    When I fill in "q" with "nomatch"
#    And I press "Search"
#    Then I should not see "first_family"
#    And I should not see "second_family"
#    And I should not see "third_family"
#    When I fill in "q" with ""
#    And I press "Search"
#    Then I should see "first_family"
#    And I should see "second_family"
#    And I should see "third_family"

  Scenario: Add provider account to pool family
    Given there is a pool family named "testpoolfamily"
    And there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And I am on the pool family provider accounts page
    Then I should see "Provider Accounts for"
    When I select "testaccount" from "provider_account_id"
    And I press "pool_family_submit"
    Then there should be 1 provider accounts assigned to "testpoolfamily"
    And I should see "testaccount"

  Scenario: Remove provider account from pool family
    Given there is a pool family named "testpoolfamily"
    And there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And there is a provider account "testaccount" related to pool family "testpoolfamily"
    And I am on the pool family provider accounts page
    Then I should see "testaccount"
    When I check "testaccount" provider account
    And I press "Remove selected"
    Then there should not exist a provider account assigned to "testpoolfamily"

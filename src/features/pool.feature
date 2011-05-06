Feature: Manage Pools
  In order to manage my cloud infrastructure
  As a user
  I want to manage my pools

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Create a new Pool
    Given I am on the pools page
    And there is not a pool named "mockpool"
    When I follow "New Pool"
    Then I should be on the new pool page
    And I should see "Create a new Pool"
    When I fill in "pool_name" with "mockpool"
    And I select "default" from "pool_pool_family_id"
    And I fill in "quota_instances" with "unlimited"
    And I press "Save"
    Then I should be on the pool page
    And I should see "Pool added"
    And I should see "mockpool"
    And I should see "default"
    And I should see "unlimited"
    And I should have a pool named "mockpool"

  @tag
  Scenario: View Pool's Quota Usage
    Given I have Pool Creator permissions on a pool named "mockpool"
    And the "mockpool" Pool has a quota with following capacities:
    | resource                  | capacity |
    | maximum_running_instances | 10       |
    | running_instances         | 8        |
    And I am on the pools page
    When I follow "mockpool"
    Then I should be on the show pool page
    When I follow "Quota"
    Then I should see the following:
    | mockpool | 10           | 80.0             |

  Scenario: Enter invalid characters into Name field
    Given I am on the new pool page
    When I fill in "pool[name]" with "@%&*())_@!#!"
    And I press "Save"
    Then I should see "Name must only contain: numbers, letters, spaces, '_' and '-'"

  Scenario: Delete pools
    Given I am on the pools page
    And a pool "Amazon Startrek Pool" exists
    And a pool "Redhat Voyager Pool" exists
    And I am on the pools page
    And there are 3 pools
    When I check "Redhat Voyager Pool" pool
    And I check "Amazon Startrek Pool" pool
    And I press "Destroy"
    Then there should only be 1 pools
    And I should be on the pools page
    When I go to the pools page
    Then I should not see "Redhat Voyager Pool"
    And I should not see "Amazon Startrek Pool"

  Scenario: Create multiple pools
    Given I am on the pools page
    And there is not a pool named "mockpool"
    And there is not a pool named "foopool"
    When I follow "New Pool"
    Then I should be on the new pool page
    And I should see "Create a new Pool"
    When I fill in "pool_name" with "mockpool"
    And I select "default" from "pool_pool_family_id"
    And I press "Save"
    Then I should be on the pool page
    And I should see "Pool added"
    And I should see "mockpool"
    And I should have a pool named "mockpool"
    When I follow "New Pool"
    Then I should be on the new pool page
    And I should see "Create a new Pool"
    When I fill in "pool_name" with "foopool"
    And I select "default" from "pool_pool_family_id"
    And I press "Save"
    Then I should be on the pool page
    And I should see "Pool added"
    And I should see "mockpool"
    And I should see "foopool"
    And I should have a pool named "mockpool"
    And I should have a pool named "foopool"

  Scenario: Cannot delete default_pool
    Given I am on the pools page
    When I check "default_pool" pool
    And I press "Destroy"
    Then I should see "The default pool cannot be deleted"
    And I should see "default_pool"

  Scenario: Cannot delete default_pool by renaming it
    Given I renamed default_pool to pool_default
    Given I am on the pools page
    When I check "pool_default" pool
    And I press "Destroy"
    Then I should see "The default pool cannot be deleted"
    And I should see "pool_default"

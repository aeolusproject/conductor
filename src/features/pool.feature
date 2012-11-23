Feature: Manage Pools
  In order to manage my cloud infrastructure
  As a user
  I want to manage my pools

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Change Provider Selection
    Given a pool "mockpool" exists
    Given I am viewing the pool "mockpool"
    And I follow "provider_selection_button"
    Then I should be on the provider selection page for "mockpool" pool
    When I click "penalty_for_failure" toggle
    Then I should be on the provider selection page for "mockpool" pool
    When I follow link with text "Configure" 
    Then I should not see "uninitialized constant"
# this test is to be alter to check for some text on the page when the bug is fixed

  Scenario: Create a new Pool
    Given I am on the pools page
    And there is not a pool named "mockpool"
    When I follow "new_pool_button"
    Then I should be on the new pool page
    When I fill in "pool_name" with "mockpool"
    And I select "default" from "pool_pool_family_id"
    And I fill in "quota_instances" with "unlimited"
    And I press "save_button"
    Then I should be on the pools page
    And I should see "mockpool"
    And I should have a pool named "mockpool"

  Scenario: View Pool's Quota Usage
    Given I have Pool Creator permissions on a pool named "mockpool"
    And the "mockpool" Pool has a quota with following capacities:
    | resource                  | capacity |
    | maximum_running_instances | 10       |
    | running_instances         | 8        |
    And I am on the pools page
    Then I should see the quota usage for the "mockpool" pool

  Scenario: Enter invalid characters into Name field
    Given I am on the new pool page
    When I fill in "pool[name]" with "@%&*())_@!#!"
    And I press "save_button"
    Then I should see "Name must only contain: numbers, letters, spaces, '_' and '-'"

  Scenario: Delete pools
    Given I am on the pools page
    And a pool "Amazon Startrek Pool" exists
    And a pool "Redhat Voyager Pool" exists
    When I go to the pools page
    And I follow link with ID "filter_view"
    Then there should be 3 pools
    When I check "Redhat Voyager Pool" pool
    And I check "Amazon Startrek Pool" pool
    And I press "delete_button"
    Then there should only be 1 pools
    And I should be on the pools page
    When I go to the pools page
    Then I should not see "Redhat Voyager Pool"
    And I should not see "Amazon Startrek Pool"

  Scenario: Create multiple pools
    Given I am on the pools page
    And there is not a pool named "mockpool"
    And there is not a pool named "foopool"
    When I follow link with ID "filter_view"
    And I follow "new_pool_button"
    Then I should be on the new pool page
    When I fill in "pool_name" with "mockpool"
    And I select "default" from "pool_pool_family_id"
    And I press "save_button"
    Then I should be on the pools page
    And I should see a confirmation message
    And I should see "mockpool"
    And I should have a pool named "mockpool"
    When I follow link with ID "filter_view"
    And I follow "new_pool_button"
    Then I should be on the new pool page
    When I fill in "pool_name" with "foopool"
    And I select "default" from "pool_pool_family_id"
    And I press "save_button"
    Then I should be on the pools page
    And I should see a confirmation message
    And I should have a pool named "mockpool"
    And I should have a pool named "foopool"

  Scenario: Cannot delete default_pool
    Given I am on the pools page
    When I follow link with ID "filter_view"
    And I check "Default" pool
    And I press "delete_button"
    Then I should see an error message
    And I should see "Default"

  Scenario: Cannot delete default_pool by renaming it
    Given I renamed Default to pool_default
    And I am on the pools page
    When I follow link with ID "filter_view"
    And I check "pool_default" pool
    And I press "delete_button"
    Then I should see an error message
    And I should see "pool_default"

  Scenario: Cannot delete pool with running instances
    Given I am on the pools page
    And a pool "Amazon Startrek Pool" exists with deployment "testdeployment"
    And the deployment "testdeployment" has an instance named "testinstance"
    When I follow link with ID "filter_view"
    And I check "Amazon Startrek Pool" pool
    And I press "delete_button"
    Then I should see an error message

  Scenario: View all pools in JSON format
    Given there are 2 pools
    And I accept JSON
    When I go to the pools page
    Then I should see 2 pools in JSON format

  Scenario: View all pools over XHR
    Given there are 2 pools
    And I request XHR
    When I go to the pools page
    Then I should get back a partial

  Scenario: View a pool in JSON format
    Given a pool "mockpool" exists
    And I accept JSON
    When I am viewing the pool "mockpool"
    Then I should see pool "mockpool" in JSON format

  Scenario: View a pool over XHR
    Given a pool "mockpool42" exists with deployment "mockdeployment"
    And I request XHR
    When I am viewing the pool "mockpool42"
    Then I should get back a partial
    And I should see "mockdeployment"

  Scenario: View a pool in filter view over XHR
    Given a pool "mockpool42" exists with deployment "mockdeployment"
    And I request XHR
    When I go to the "mockpool42" pool filter view page
    Then I should get back a partial
    And I should see the "mockdeployment" deployment

  Scenario: Switch pretty view to filtred view on pools index
    Given I am on the pools page
    And I see "Overview"
    And I follow link with ID "filter_view"
    Then I should see the filter_view contents for pools index

  Scenario: Don't display dropdown toggle in pretty view when there is only one pool
    Given I am on the pools page
    Then there should be 1 pools
    Then I should not see "Expand/Collapse" within ".pool.overview .statistics"

  Scenario: Switch from filtred view to pretty view on pools index
    Given I am on the pools page
    And I follow link with ID "filter_view"
    When I follow link with ID "pretty_view"
    Then I should see the pretty_view contents for pools index

  Scenario: Display alerts
    And there is a "fail1" failed instance owned by "admin"
    When I go to the pools page
    Then I should see "Alerts"
    And I should see "Instance Failure error"

  Scenario: Pools#show pretty view
    Given a pool "mockpool" exists with deployment "mockdeployment"
    When I am viewing the pool "mockpool"
    And I follow link with ID "pretty_view"
    Then I should not see "0 Instances" within ".content.collapsible.toggle-view.pools"

  Scenario: Pools#show filter view
    Given a pool "mockpool" exists with deployment "mockdeployment"
    When I am viewing the pool "mockpool"
    And I follow link with ID "filter_view"
    Then I should not see "0 Instances" within ".content.collapsible.toggle-view.pools"

  Scenario: Hide/Show stopped instances
    Given I am on the pools page
    And there is a "mock1" running instance
    And there is a "mock2" running instance
    And there is a "mock3" stopped instance
    When I follow link with ID "filter_view"
    And I follow "details_instances"
    And I should see "mock1"
    And I should see "mock2"
    And I should see "mock3"
    When I select "Non-stopped Instances" from "instances_preset_filter"
    And I press "apply_instances_preset_filter"
    And I should see "mock1"
    And I should see "mock2"
    And I should not see "mock3"

  Scenario: Select Catalog Images on pool detail page
    Given a pool "mockpool" exists
    And "mockpool" has catalog "mockcatalog"
    And "mockcatalog" has catalog_entry "mockcatalogentry"
    When I am viewing the pool "mockpool"
    And I follow link with ID "details_images"
    Then I should see a pools "mockcatalog" within "#tab"

  Scenario: Filter Pools
    Given a pool "mypool" exists
    And a pool "somepool" exists with deployment "somedeployment"
    And I am on the pools filter view page
    Then I should see "mypool"
    And I should see "somepool"
    When I select "With running Instances" from "pools_preset_filter"
    And I press "apply_pools_preset_filter"
    Then I should see "somepool"
    And I should not see "mypool"

  Scenario: Search Pools
    Given a pool "mypool" exists
    And a pool "somepool" exists
    And I am on the pools filter view page
    Then I should see "mypool"
    And I should see "somepool"
    When I fill in "pools_search" with "some"
    And I press "apply_pools_search"
    Then I should see "somepool"
    And I should not see "mypool"
    When I fill in "pools_search" with "mypool"
    And I press "apply_pools_search"
    Then I should see "mypool"
    And I should not see "somepool"

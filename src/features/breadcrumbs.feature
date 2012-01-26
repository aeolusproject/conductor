Feature: Breadcrumbs
  In order to get back to visited page
  As a user
  I want the application to include a breadcrumb trail for site navigation

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Save breadcrumb and use it for navigation
    Given I am on the deployments page
    And a pool "testpool" exists
    When I go to the pools page
    Then I should see "testpool"
    When I follow "testpool"
    Then I should see "Pools" within "#nav_history"
    When I follow "Pools" within "#nav_history"
    Then I should be on the pools page

  Scenario: Don't show breadcrumbs on the top level section
    Given a pool "testpool" exists
    And I am on the page for the pool "testpool"
    When I go to the pools page
    Then I should not see the breadcrumbs section
    When I go to the pools page
    Then I should not see the breadcrumbs section

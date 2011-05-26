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
    Then I should see "Pools"
    When I follow "Pools"
    Then I should be on the pools page

  Scenario: Dont create breadcrumb when reloading or pointing to the same route
    Given I am on the deployments page
    When I go to the pools page
    And I go to the pools page
    Then I should see "Deployments"

Feature: Manage Deployments
  In order to manage my cloud infrastructure
  As a user
  I want to manage my deployments

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List deployments
    Given I am on the homepage
    And there is a deployment named "MySQL Cluster" belonging to "Databases" owned by "bob"
    When I go to the resources deployments page
    Then I should see "MySQL Cluster"
    And I should see "bob"

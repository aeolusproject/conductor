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

  Scenario: Launch new deployment
    Given there is a deployable named "testdeployable"
    And There is a mock pulp repository
    And there is a "testtemplate" template
    And there is an assembly named "testassembly" belonging to "testdeployable"
    And there is an assembly named "testassembly" belonging to "testtemplate" template
    When I go to the resources deployments page
    And I press "Launch new"
    Then I should see "Launch new deployment via"
    When I select "testdeployable" from "deployable_id"
    When I press "Launch"
    Then I should see "Launch deployable"

  Scenario: Stop deployments
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    When I go to the resources deployments page
    Then I should see "testdeployment"
    When I check "testdeployment" deployment
    And I press "Stop"
    Then I should see "testdeployment"

  Scenario: Show operational status of deployment
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    When I am on the operational status of deployment page
    Then I should see "Operational status of testdeployment"
    And I should see "Uptime"

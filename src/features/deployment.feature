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
    When I go to the deployments page
    Then I should see "MySQL Cluster"
    And I should see "bob"

  Scenario: Launch new deployment
    Given there is a deployable named "testdeployable"
    And There is a mock pulp repository
    And there is a "testtemplate" template
    And there is an assembly named "testassembly" belonging to "testdeployable"
    And there is an assembly named "testassembly" belonging to "testtemplate" template
    When I go to the deployments page
    And I press "Launch new"
    Then I should see "Launch new deployment via"
    When I select "testdeployable" from "deployable_id"
    When I press "Launch"
    Then I should see "Launch deployable"

  Scenario: Stop deployments
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    When I go to the deployments page
    Then I should see "testdeployment"
    When I check "testdeployment" deployment
    And I press "Stop"
    Then I should see "testdeployment"

  Scenario: Show operational status of deployment
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    When I am on the operational status of deployment page
    Then I should see "Operational status of testdeployment"
    And I should see "Uptime"

  Scenario: Edit deployment name
    Given there is a deployment named "Hudson" belonging to "QA Infrastructure" owned by "joe"
    When I go to Hudson's edit deployment page
    Then I should see "Edit deployment"
    When I fill in "name" with "Jenkins"
    And I press "Save"
    Then I should be on Jenkins's deployment page
    And I should see "Jenkins"

  Scenario: View all deployments in JSON format
    Given There is a mock pulp repository
    And there are 2 deployments
    And I accept JSON
    When I go to the deployments page
    Then I should see 2 deployments in JSON format

  Scenario: View a deployment in JSON format
    Given There is a mock pulp repository
    And a deployment "mockdeployment" exists
    And I accept JSON
    When I am viewing the deployment "mockdeployment"
    Then I should see deployment "mockdeployment" in JSON format

  Scenario: Create a deployment and get JSON response
    Given There is a mock pulp repository
    And I accept JSON
    When I create a deployment
    Then I should get back a deployment in JSON format

  Scenario: Stop a deployment
    Given a deployment "mockdeployment" exists
    And There is a mock pulp repository
    And I accept JSON
    When I stop "mockdeployment" deployment
    Then I should get back JSON object with success and errors

Feature: Manage Deployments
  In order to manage my cloud infrastructure
  As a user
  I want to manage my deployments

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List deployments
    Given there is a deployment named "MySQL Cluster" belonging to "Databases" owned by "bob"
    And I am on the pools page
    When I follow link with ID "filter_view"
    And I follow "details_deployments" within "#tab-container-1-nav"
    Then I should see "MySQL Cluster"
    And I should see "bob"

  Scenario: List deployments over XHR
    Given there is a deployment named "MySQL Cluster" belonging to "Databases" owned by "bob"
    And I am on the pools page
    And I request XHR
    When I follow link with ID "filter_view"
    And I follow "details_deployments"
    Then I should see "MySQL Cluster"
    And I should see "bob"

  Scenario: Launch new deployment
    Given a pool "mockpool" exists
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    When I am viewing the pool "mockpool"
    And I follow "new_deployment_button"
    Then I should see "New Deployment"
    When I fill in "deployable_url" with "http://localhost/deployables/deployable1.xml"
    When I fill in "deployment_name" with "mynewdeployment"
    When I press "next_button"
    Then I should see "Deployable details"
    When I press "launch_deployment"
    Then I should see "Deployment launched"
    Then I should see "mynewdeployment Deployment"
    And I should see "mynewdeployment/frontend"
    And I should see "mynewdeployment/backend"

  Scenario: Launch new deployment over XHR
    Given a pool "mockpool" exists
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    When I am viewing the pool "mockpool"
    And I request XHR
    And I follow "new_deployment_button"
    Then I should get back a partial
    Then I should see "New Deployment"
    When I fill in "deployable_url" with "http://localhost/deployables/deployable1.xml"
    When I fill in "deployment_name" with "mynewdeployment"
    When I press "next_button"
    Then I should see "Deployable details"
    When I press "launch_deployment"
    Then I should see "Created"
    Then I should see "mynewdeployment"

  Scenario: Launch a deployment in a disabled pool
    Given a pool "Disabled" exists and is disabled
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    When I am viewing the pool "Disabled"
    And I follow "new_deployment_button"
    Then I should see "pool has been disabled"
    And I should be on the page for the pool "Disabled"

  Scenario: Stop deployments
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    When I go to the deployments page
    Then I should see "testdeployment"
    When I check "testdeployment" deployment
    And I press "stop_button"
    Then I should see "testdeployment"

  Scenario: Stop a deployment over XHR
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    And I request XHR
    When I go to the deployments page
    Then I should get back a partial
    And I should see "testdeployment"
    When I check "testdeployment" deployment
    And I press "stop_button"
    Then I should get back a partial
    And I should see "testdeployment"

  Scenario: Show operational status of deployment
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    When I am on the deployments page
    And I follow "testdeployment"
    Then I should see "testdeployment"

  Scenario: Edit deployment name
    Given there is a deployment named "Hudson" belonging to "QA Infrastructure" owned by "joe"
    When I go to Hudson's edit deployment page
    Then I should see "Edit deployment"
    When I fill in "deployment_name" with "Jenkins"
    And I press "save_button"
    Then I should be on Jenkins's deployment page
    And I should see "Jenkins"

  Scenario: Edit deployment name using XHR
    Given there is a deployment named "Hudson" belonging to "QA Infrastructure" owned by "joe"
    And I request XHR
    When I go to Hudson's edit deployment page
    Then I should get back a partial
    And I should see "Edit deployment"
    When I fill in "deployment_name" with "Jenkins"
    And I press "save_button"
    Then I should get back a partial
    And I should be on Jenkins's deployment page
    And I should see "Jenkins"

  Scenario: View all deployments in JSON format
    Given there are 2 deployments
    And I accept JSON
    When I go to the deployments page
    Then I should see 2 deployments in JSON format

  Scenario: View a deployment in JSON format
    Given a deployment "mockdeployment" exists
    And I accept JSON
    When I am viewing the deployment "mockdeployment"
    Then I should see deployment "mockdeployment" in JSON format

  Scenario: View a deployment via XHR
    Given a deployment "mockdeployment" exists
    And the deployment "mockdeployment" has an instance named "myinstance"
    And I request XHR
    When I am viewing the deployment "mockdeployment"
    Then I should get back a partial
    And I should see "myinstance"

  #Scenario: Create a deployment and get JSON response
  #  Given I accept JSON
  #  When I create a deployment
  #  Then show me the page
  #  Then I should get back a deployment in JSON format

  Scenario: Create a deployment and get XHR response
    Given I request XHR
    When I create a deployment
    Then I should get back a partial

  Scenario: Stop a deployment
    Given a deployment "mockdeployment" exists
    And I accept JSON
    When I stop "mockdeployment" deployment
    Then I should get back JSON object with success and errors

  Scenario: Provider invalid deployable xml URL when launching a deployment
    Given a pool "mockpool" exists
    When I am viewing the pool "mockpool"
    And I follow "new_deployment_button"
    Then I should see "New Deployment"
    When I fill in "deployable_url" with "http://invalid.deployable.url/"
    And I fill in "deployment_name" with "mynewdeployment"
    And I press "next_button"
    Then I should see "New Deployment"
    And I should see "Deployment Details"
    And I should see "failed to get the deployable definition"

  Scenario: Show deployment switch to deployment properties and back
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    When I am on the deployments page
    And I follow "testdeployment"
    And I should see "testdeployment"
    And I follow "Properties"
    Then I should see the following:
      | Property Name | Value          |
      | Pool	        | Default   |
      | Owner	        | John testuser  |
      | Name	        | testdeployment |

    When I follow "details_instances"
    Then I should see "testdeployment"

  Scenario: Delete a deployment
    Given there is a deployment named "testdeployment" belonging to "testdeployable" owned by "testuser"
    And I am on the pools page
    When I follow "testdeployment"
    And I press "delete_button"
    Then I should see "The deployment testdeployment was scheduled for deletion"

  Scenario: Delete a deployment with running instances
    Given a deployment "mockdeployment" exists
    And the deployment "mockdeployment" has an instance named "myinstance"
    And the instance "myinstance" is in the running state
    And I am on the pools page
    When I follow "mockdeployment"
    And I press "delete_button"
    Then I should see "The deployment mockdeployment was scheduled for deletion"

  Scenario: Launch a deployment which is not launchable
    Given a pool "mockpool" exists
    And there is "front_hwp1" conductor hardware profile
    When I am viewing the pool "mockpool"
    And I follow "New Deployment"
    Then I should see "New Deployment"
    When I fill in "deployable_url" with "http://localhost/deployables/deployable1.xml"
    When I fill in "deployment_name" with "mynewdeployment"
    When I press "Next"
    Then I should see "Deployable details"
    And I should see "Some assemblies will not be launched:"
    And I should see "backend: Hardware Profile front_hwp2 not found."

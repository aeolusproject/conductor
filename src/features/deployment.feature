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

  #It's difficult to mock out all the dependencies to get the instance launching
  #working in a testable scenario.
  Scenario: Launch new deployment
    Given a pool "mockpool" exists
    And "mockpool" has catalog "test"
    And "test" has catalog_entry "test_catalog_entry"
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    And there is mock provider account "my_mock_provider"
    And there is a provider account "my_mock_provider" related to pool family "default"
    When I am viewing the pool "mockpool"
    And I follow "new_deployment_button"
    Then I should be on the launch new deployments page
    When I select "test_catalog_entry" from "deployable_id"
    When I fill in "deployment_name" with "mynewdeployment"
    When I press "next_button"
    Then I should see "Are you sure you wish to deploy"
    When I press "launch_deployment_button"
    Then I should see a confirmation message
    And I should see "mynewdeployment/frontend"
    And I should see "mynewdeployment/backend"

  Scenario: Launch new deployment over XHR
    Given a pool "mockpool" exists
    And "mockpool" has catalog "test"
    And "test" has catalog_entry "test_catalog_entry"
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    When I am viewing the pool "mockpool"
    And I request XHR
    And I follow "new_deployment_button"
    Then I should get back a partial
    And I should be on the launch new deployments page
    When I select "test_catalog_entry" from "deployable_id"
    When I fill in "deployment_name" with "mynewdeployment"
    When I press "next_button"
    Then I should see "Are you sure you wish to deploy"
    When I press "launch_deployment_button"
    Then I should see "Created"
    Then I should see "mynewdeployment"

  Scenario: Launch a deployment in a disabled pool
    Given a pool "Disabled" exists and is disabled
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    When I am viewing the pool "Disabled"
    And I follow "new_deployment_button"
    Then I should see a warning message
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

  Scenario: Create a deployment and get XHR response
    Given I request XHR
    When I create a deployment
    Then I should get back a partial

  Scenario: Stop a deployment
    Given a deployment "mockdeployment" exists
    And I accept JSON
    When I stop "mockdeployment" deployment
    Then I should get back JSON object with success and errors

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
    And I press "delete"
    Then I should see a confirmation message

  Scenario: Delete multiple deployments
    Given a deployment "mydeployment1" exists
    And a deployment "mydeployment2" exists
    And I am on the pools page
    When I follow link with ID "filter_view"
    And I follow "details_deployments"
    And I check "mydeployment1" deployment
    And I check "mydeployment2" deployment
    And I press "delete_button"
    Then I should see "mydeployment1"
    Then I should see "mydeployment2"
    Then I should see a confirmation message

  Scenario: Delete a deployment with running instances
    Given a deployment "mockdeployment" exists
    And the deployment "mockdeployment" has an instance named "myinstance"
    And the instance "myinstance" is in the running state
    And I am on the pools page
    When I follow "mockdeployment"
    And I press "delete"
    Then I should see a confirmation message

  Scenario: Launch a deployment which is not launchable
    Given a pool "mockpool" exists
    And "mockpool" has catalog "test"
    And "test" has catalog_entry "test_catalog_entry"
    And there is "front_hwp1" conductor hardware profile
    When I am viewing the pool "mockpool"
    And I follow "new_deployment_button"
    Then I should be on the launch new deployments page
    When I select "test_catalog_entry" from "deployable_id"
    When I fill in "deployment_name" with "mynewdeployment"
    When I press "next_button"
    Then I should see "Are you sure you wish to deploy"
    And I should see an error message
    And I should see "front_hwp2 not found."

  Scenario: Verify that the launch parameters are displayed
    Given a pool "mockpool" exists
    And "mockpool" has catalog "test"
    And "test" has catalog_entry with parameters "test_catalog_entry"
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    And there is mock provider account "my_mock_provider"
    And there is a provider account "my_mock_provider" related to pool family "default"
    When  I am viewing the pool "mockpool"
    And   I follow "new_deployment_button"
    Then  I should be on the launch new deployments page
    When  I select "test_catalog_entry" from "deployable_id"
    And   I fill in "deployment_name" with "deployment_with_launch_parameters"
    And   I press "next_button"
    Then  I should see "Configure launch-time parameters"
    And   I should see "Parameter 1"
    And   I should see "Parameter 2"

  Scenario: Verify that the launch parameters are required
    Given a pool "mockpool" exists
    And "mockpool" has catalog "test"
    And "test" has catalog_entry with parameters "test_catalog_entry"
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    And there is mock provider account "my_mock_provider"
    And there is a provider account "my_mock_provider" related to pool family "default"
    And there is a mock config server "https://mock:443" for account "my_mock_provider"
    When  I am viewing the pool "mockpool"
    And   I follow "new_deployment_button"
    Then  I should be on the launch new deployments page
    When  I select "test_catalog_entry" from "deployable_id"
    And   I fill in "deployment_name" with "deployment_with_launch_parameters"
    And   I press "next_button"
    Then  I should see "Configure launch-time parameters"
    And   I should see "Launch Parameter 1"
    And   I should see "Launch Parameter 2"
    When  I fill in "deployment_launch_parameters_assembly_with_launch_parameters_service_with_launch_parameters_launch_parameter_1" with "value_1"
    And   I press "submit_params"
    Then  I should see "Are you sure you wish to deploy"
    When  I press "launch_deployment_button"
    Then  I should see "launch_parameter_2 cannot be blank"

  Scenario: Search deployments
    Given a deployment "mydeployment" exists
    And a deployment "somedeployment" exists
    And I am on the deployments page
    Then I should see "mydeployment"
    And I should see "somedeployment"
    When I fill in "deployments_search" with "some"
    And I press "apply_deployments_search"
    Then I should see "somedeployment"
    And I should not see "mydeployment"
    When I fill in "deployments_search" with "mydeployment"
    And I press "apply_deployments_search"
    Then I should see "mydeployment"
    And I should not see "somedeployment"

  Scenario: Launch from catalog page
    Given there is a "catalog" catalog with deployable
    And there is a "front_hwp1" hardware profile
    And there is a "front_hwp2" hardware profile
    When I am on the launch from the catalog "catalog" page
    Then I should see "my"
    And I should see "front_hwp1"
    And I should see "front_hwp2"

  Scenario: Launch from catalog page with hardware profile missing
    Given there is a "catalog" catalog with deployable
    And there is no "front_hwp1" hardware profile
    And there is a "front_hwp2" hardware profile
    When I am on the launch from the catalog "catalog" page
    Then I should see "my"
    And I should not see "front_hwp1"
    And I should see "front_hwp2"

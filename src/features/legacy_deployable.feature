Feature: Manage Deployables
  In order to manage my cloud infrastructure
  As a user
  I want to manage deployables

  Background:
    Given I am an authorised user
    And I am logged in
    And There is a mock pulp repository

  Scenario: List deployables
    Given I am on the homepage
    And there is a deployable named "MySQL cluster"
    When I go to the legacy_deployables page
    Then I should see "MySQL cluster"

  Scenario: Create a new Deployable
    Given there is a deployable named "MySQL cluster"
    And I am on the legacy_deployables page
    When I follow "Create"
    Then I should be on the new legacy_deployable page
    And I should see "New Deployable"
    When I fill in "legacy_deployable[name]" with "App"
    And I press "Save"
    Then I should be on App's deployable page
    And I should see "Deployable added"
    And I should have a deployable named "App"
    And I should see "App"

  Scenario: Edit a deployable
    Given there is a deployable named "MySQL cluster"
    And I am on the legacy_deployables page
    When I follow "MySQL cluster"
    And I follow "Edit"
    Then I should be on the edit legacy_deployable page
    And I should see "Editing Deployable"
    When I fill in "legacy_deployable[name]" with "AppModified"
    And I press "Save"
    Then I should be on AppModified's deployable page
    And I should see "Deployable updated"
    And I should have a deployable named "AppModified"
    And I should see "AppModified"

  Scenario: Delete a deployable
    Given there is a deployable named "App"
    And I am on the legacy_deployables page
    When I check the "App" deployable
    And I press "Delete"
    Then I should be on the legacy_deployables page
    And there should be no deployables

  Scenario: Add an assembly to a deployable
    Given there is a deployable named "Webserver"
    Given there is an assembly named "Apache"
    And I am on the legacy_deployables page
    When I follow "Webserver"
    And I follow "details_Assemblies"
    And I follow "Add Assembly..."
    Then I should see "Apache"
    When I check the "Apache" assembly
    And I press "Save"
    Then I should see "Assemblies saved."
    And I should see "Apache"

  Scenario: Remove an assembly from a deployable
    Given there is a deployable named "Webserver"
    Given there is an assembly named "Apache" belonging to "Webserver"
    And I am on the legacy_deployables page
    When I follow "Webserver"
    And I follow "details_Assemblies"
    Then I should see "Apache"
    When I check the "Apache" assembly
    And I press "Remove Selected"
    Then I should see "Assemblies removed."
    And I should not see "Apache"

  Scenario: Search for deployables
    Given there is a deployable named "first"
    And there is a deployable named "second"
    And I am on the legacy_deployables page
    Then I should see "first"
    And I should see "second"
    When I fill in "q" with "first"
    And I press "Search"
    Then I should see "first"
    And I should not see "second"
    When I fill in "q" with "second"
    And I press "Search"
    Then I should see "second"
    And I should not see "first"
    When I fill in "q" with ""
    And I press "Search"
    Then I should see "first"
    And I should see "second"

  Scenario: Show list of deployments belongs to deployable
    Given there is a deployable named "My"
    And there are deployment named "My deployment" belongs to "My"
    When I am on the deployable deployments page
    Then I should see "My deployment"

  Scenario: Create and launch a deployment from a deployable
    Given there is a factory deployable named "test1"
    And I am on the legacy_deployables page
    And there is "mock_profile" conductor hardware profile
    And there is "mock_realm" frontend realm
    And there is "mock_pool" pool
    When I follow "test1"
    And I follow "Launch"
    Then I should be on the legacy new deployments page
    When I fill in "deployment_name" with "depl1"
    And I select "mock_pool" from "deployment_pool_id"
    And I select "mock_realm" from "deployment_frontend_realm_id"
    And I select default hardware profile for assemblies in "test1"
    And I press "Launch"
    Then I should see "Deployment launched"

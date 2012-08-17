Feature: Config Servers
  In order to administer configuration management on systems
  As a user
  I want to manage config servers as part of provider accounts

  Background:
    Given I am an authorised user
    And I am logged in

  # This scenario relies on a stubbed version of ConfigServer
  # that never fails on the connection test
  Scenario: I am able to add a config server to a provider account
    Given I am on the homepage
    And there is mock provider account "mock_account"
    And I want to add a new config server
    When I go to mock's provider mock_account's provider account page
    Then I should see "None" within "#config_server"
    And I should see "[ Add ]" within "#config_server_control"
    When I follow "Add"
    Then I should be on the new config server page
    When I fill in "config_server[endpoint]" with "valid"
    And I fill in "config_server[key]" with "valid"
    And I fill in "config_server[secret]" with "valid"
    And I press "Save"
    Then I should be on mock's provider mock_account's provider account page
    And I should see "Config Server added"
    And I should see "[ Edit ]" within "#config_server_control"

  # This is essentially the same scenario as the first, but creates
  # a different stubbed ConfigServer, so it fails
  Scenario: I cannot add a config server with invalid endpoint
    Given I am on the homepage
    And there is mock provider account "mock_account"
    And I am not sure about the config server endpoint
    When I go to mock's provider mock_account's provider account page
    Then I should see "None" within "#config_server"
    And I should see "[ Add ]" within "#config_server_control"
    When I follow "Add"
    Then I should be on the new config server page
    When I fill in "config_server[endpoint]" with "invalid"
    And I fill in "config_server[key]" with "valid"
    And I fill in "config_server[secret]" with "valid"
    And I press "Save"
    Then I should see "The Config Server information is invalid"
    And I should see "Could not validate Config Server connection"

  # This is essentially the same scenario as the first, but creates
  # a different stubbed ConfigServer, so it fails
  Scenario: I cannot add a config server with invalid credentials
    Given I am on the homepage
    And there is mock provider account "mock_account"
    And I am not sure about the config server credentials
    When I go to mock's provider mock_account's provider account page
    Then I should see "None" within "#config_server"
    And I should see "[ Add ]" within "#config_server_control"
    When I follow "Add"
    Then I should be on the new config server page
    When I fill in "config_server[endpoint]" with "valid"
    When I fill in "config_server[key]" with "invalid"
    When I fill in "config_server[secret]" with "invalid"
    And I press "Save"
    Then I should see "The Config Server information is invalid"
    And I should see "Could not validate Config Server connection"

  Scenario: I should be able to edit a config server
    Given I am on the homepage
    And there is a mock config server "https://mock:443" for account "mock_account"
    When I go to mock's provider mock_account's provider account page
    Then I should see "[ Edit ]" within "#config_server_control"
    When I follow "Edit" within "#config_server_control"
    Then I should be on the edit config server page for account "mock_account"
    And I press "Save"
    Then I should be on mock's provider mock_account's provider account page
    And I should see "Config Server updated"

  Scenario: I should be able to delete an existing config server
    Given I am on the homepage
    And there is a mock config server "https://mock:443" for account "mock_account"
    When I go to mock's provider mock_account's provider account page
    Then I should see "[ Delete ]" within "#config_server_control"
    When I follow "Delete" within "#config_server_control"
    Then I should see "Config Server was deleted"
    And I should be on mock's provider mock_account's provider account page

  Scenario: I should be able to test a correctly configured and available config server
    Given I am on the homepage
    And there is a mock config server "https://mock:443" for account "mock_account"
    When I go to mock's provider mock_account's provider account page
    Then I should see "[ Test ]" within "#config_server_control"
    When I follow "Test" within "#config_server_control"
    Then I should see "Test successful"
    And I should be on mock's provider mock_account's provider account page

  Scenario: I should see an error when I test a config server with invalid credentials
    Given I am on the homepage
    And there is a mock config server "https://bad_credentials" for account "mock_account"
    When I go to mock's provider mock_account's provider account page
    Then I should see "[ Test ]" within "#config_server_control"
    When I follow "Test" within "#config_server_control"
    Then I should see "Could not validate Config Server connection"
    And I should see "Unauthorized"

  Scenario: I should see an error when I test a config server with an invalid endpoint
    Given I am on the homepage
    And there is a mock config server "https://bad_host" for account "mock_account"
    When I go to mock's provider mock_account's provider account page
    Then I should see "[ Test ]" within "#config_server_control"
    When I follow "Test" within "#config_server_control"
    Then I should see "Could not validate Config Server connection"
    And I should see "Connection timed out"

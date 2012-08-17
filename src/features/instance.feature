# language: en
Feature: Manage Instances
  In order to manage my cloud infrastructure
  As a user
  I want to manage instances

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Download an Instance Key
    Given a mock running instance exists
    And I am viewing the mock instance detail
    And I see "SSH key"
    When I follow "download_ssh_key"
    Then I should see the Save dialog for a .pem file

  Scenario: Download an Instance Key over XHR
    Given a mock running instance exists
    And I request XHR
    When I am viewing the mock instance detail
    And I see "SSH key"
    When I follow "download_ssh_key"
    Then I should see the Save dialog for a .pem file

  Scenario: Don't see' an Instance Key
    Given a mock pending instance exists
    When I am viewing the pending instance detail
    Then I should not see "SSH key"

  Scenario: Get useful error when going to wrong url
    Given a mock pending instance exists
    When I manually go to the key action for this instance
    Then I should see "SSH Key not found for this Instance."

  Scenario: I want to view all instances
    Given there is a "mock1" instance
    And I am on the home page
    When I follow "monitor"
    Then I should be on the pools page
    When I follow "filter_view"
    And I follow "details_instances"
    Then I should be on the pools page
    And I should see "mock1"

  Scenario: I want to view all instances over XHR
    Given there is a "mock1" instance
    And I request XHR
    When I am on the instances page
    Then I should get back a partial
    And I should see "mock1"

  Scenario: Show instance details
    Given there is a "mock1" instance
    And I am on the instances page
    When I follow "mock1"
    Then I should see instance details

  Scenario: Show instance details over XHR
    Given there is a "mock1" instance
    And I request XHR
    When I am on mock1's instance page
    Then I should get back a partial
    And I should see "Name"

  Scenario: Stop instance
    Given there is a "mock1" running instance
    And I am on the instances page
    When I check "mock1" instance
    And I press "stop_selected_instances"
    Then I should be on the instances page
    And I should see "mock1: stop action was successfully queued."

  Scenario: Stop inaccessible instance
    Given there is a "mock1" running instance
    And I am on the instances page
    And "mock1" instance's provider is not accessible
    When I check "mock1" instance
    And I press "stop_selected_instances"
    Then I should see "Terminate Instances"
    And I should see "mock1"
    When I press "terminate_button"
    Then I should see "mock1: state changed to stopped"

  Scenario: Stop multiple instances
    Given there is a "mock1" running instance
    And there is a "mock2" running instance
    And there is a "mock3" stopped instance
    And I am on the instances page
    When I check "mock1" instance
    And I check "mock2" instance
    And I check "mock3" instance
    And I press "stop_selected_instances"
    Then I should be on the instances page
    And I should see "mock1: stop action was successfully queued"
    And I should see "mock2: stop action was successfully queued"
    And I should see "mock3: Stop is an invalid action"

  # not supported in UI now
  #@tag
  #Scenario: Search for instances
  #  Given there are the following instances:
  #  | name      | external_key | state   | public_addresses    | private_addresses     |
  #  | mockname  | ext_mock     | running | mock.public.address  | mock.private.address  |
  #  | test      | ext_test     | pending | test.public.address  | test.private.address  |
  #  | other     | ext_other    | stopped | other.public.address | other.private.address |
  #  And there is the following instance with a differently-named owning user:
  #  | name  | external_key | state   | public_addresses    | private_addresses     |
  #  | foo   | ext_foo      | stopped | foo.public.address  | foo.private.address   |
  #  And I am on the the instances page
  #  When I fill in "q" with "mockname"
  #  And I press "Search"
  #  Then I should see "mock"
  #  And I should not see "test"
  #  And I should not see "other"
  #  And I should not see "foo"
  #  When I fill in "q" with "ext_other"
  #  And I press "Search"
  #  Then I should not see "mock"
  #  And I should not see "test"
  #  And I should see "other"
  #  And I should not see "foo"
  #  When I fill in "q" with "pending"
  #  And I press "Search"
  #  Then I should not see "mock"
  #  And I should see "test"
  #  And I should not see "other"
  #  And I should not see "foo"
  #  When I fill in "q" with "mock.public.address"
  #  And I press "Search"
  #  Then I should see "mock"
  #  And I should not see "test"
  #  And I should not see "other"
  #  And I should not see "foo"
  #  When I fill in "q" with "test.private.address"
  #  And I press "Search"
  #  Then I should not see "mock"
  #  And I should see "test"
  #  And I should not see "other"
  #  And I should not see "foo"
  #  When I fill in "q" with "Doe"
  #  And I press "Search"
  #  Then I should not see "mock"
  #  And I should not see "test"
  #  And I should not see "other"
  #  And I should see "foo"


  Scenario: Instance with correct id is displayed when id is greater than 10
    Given there are 10 instances
    And there is a "mock1" instance
    And I am on the the instances page
    When I follow "mock1"
    Then I should see "Properties"

  Scenario: Edit an instance name
    Given there is a "Tomct" instance
    And I am on Tomct's edit instance page
    And I fill in "instance_name" with "Tomcat"
    And I press "save"
    Then I should be on Tomcat's instance page
    And I should see "Tomcat"

  Scenario: Edit an instance name over XHR
    Given there is a "Tomct" instance
    And I request XHR
    When I am on Tomct's edit instance page
    And I fill in "instance_name" with "Tomcat"
    And I press "save"
    Then I should get back a partial
    And I should see "Tomcat"

  Scenario: View all instances in JSON format
    Given there are 2 instances
    And I accept JSON
    When I go to the instances page
    Then I should see 2 instances in JSON format

  Scenario: View all instances over XHR
    Given there are 2 instances
    And I request XHR
    When I go to the instances page
    Then I should get back a partial

  Scenario: View an instance in JSON format
    Given a mock running instance exists
    And I accept JSON
    When I am viewing the mock instance
    Then I should see mock instance in JSON format

  Scenario: View an instance over XHR
    Given a mock running instance exists
    And I request XHR
    When I am viewing the mock instance
    Then I should get back a partial

  #Scenario: Create an instance over XHR
  #  Given I request XHR
  #  When I create mock instance
  #  Then I should get back a partial

  Scenario: Stop an instance
    Given there is a "mock1" running instance
    And I accept JSON
    When I stop "mock1" instance
    Then I should get back JSON object with success and errors

  Scenario: Show instance history
    Given a mock running instance exists
    And I am viewing the mock instance detail
    And I follow "details_history"
    Then I should see "created"

  Scenario: Filter Instances
    Given there is a "myinstance" running instance
    And there is a "someinstance" stopped instance
    And I am on the instances page
    Then I should see "myinstance"
    And I should see "someinstance"
    When I select "Stopped Instances" from "instances_preset_filter"
    And I press "apply_instances_preset_filter"
    Then I should not see "myinstance"
    And I should see "someinstance"

  Scenario: Search instances
    Given there is a "myinstance" instance
    And there is a "someinstance" instance
    And I am on the instances page
    Then I should see "myinstance"
    And I should see "someinstance"
    When I fill in "instances_search" with "some"
    And I press "apply_instances_search"
    Then I should see "someinstance"
    And I should not see "myinstance"
    When I fill in "instances_search" with "myinstance"
    And I press "apply_instances_search"
    Then I should see "myinstance"
    And I should not see "someinstance"

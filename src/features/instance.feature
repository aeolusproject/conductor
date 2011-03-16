# language: en
Feature: Mange Instances
  In order to manage my cloud infrastructure
  As a user
  I want to manage instances

  Background:
    Given I am an authorised user
    And I am logged in
    And There is a mock pulp repository

  Scenario: Download an Instance Key
    Given a mock running instance exists
    And I am viewing the mock instance detail
    And I see "SSH key"
    When I follow "Download"
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
    When I follow "Resource Management"
    Then I should be on the pools page
    When I follow "Instances"
    Then I should be on the instances page
    And I should see "mock1"

  Scenario: Launch instance
    Given there is an uploaded image for a template
    And I am on the instances page
    And there is "mock_profile" conductor hardware profile
    And there is "mock_realm" frontend realm
    And there is "mock_pool" pool
    When I press "Create"
    Then I should see "Show Templates"
    When I press "Launch"
    Then I should be on the new instance page
    When I fill in "instance_name" with "mock1"
    And I select "mock_profile" from "instance_hardware_profile_id"
    And I select "mock_pool" from "instance_pool_id"
    And I select "mock_realm" from "instance_frontend_realm_id"
    And I press "Launch"
    Then I should be on the instances page
    And I should see "mock1"

  Scenario: Show instance details
    Given there is a "mock1" instance
    And I am on the instances page
    When I follow "mock1"
    And I should see "Name"
    And I should see "Status"
    And I should see "Base Template"

  Scenario: Remove failed instances
    Given there is a "mock1" failed instance
    And I am on the instances page
    When I check "mock1" instance
    And I press "Remove failed"
    Then I should be on the instances page
    And I should see "mock1: remove failed action was successfully queued"

  Scenario: Stop instance
    Given there is a "mock1" running instance
    And I am on the instances page
    When I check "mock1" instance
    And I press "Stop"
    Then I should be on the instances page
    And I should see "mock1: stop action was successfully queued"

  @tag
  Scenario: Search for instances
    Given there are the following instances:
    | name      | external_key | state   | public_addresses    | private_addresses     |
    | mockname  | ext_mock     | running | mock.public.address  | mock.private.address  |
    | test      | ext_test     | pending | test.public.address  | test.private.address  |
    | other     | ext_other    | stopped | other.public.address | other.private.address |
    And there is the following instance with a differently-named owning user:
    | name  | external_key | state   | public_addresses    | private_addresses     |
    | foo   | ext_foo      | stopped | foo.public.address  | foo.private.address   |
    And I am on the the instances page
    When I fill in "q" with "mockname"
    And I press "Search"
    Then I should see "mock"
    And I should not see "test"
    And I should not see "other"
    And I should not see "foo"
    When I fill in "q" with "ext_other"
    And I press "Search"
    Then I should not see "mock"
    And I should not see "test"
    And I should see "other"
    And I should not see "foo"
    When I fill in "q" with "pending"
    And I press "Search"
    Then I should not see "mock"
    And I should see "test"
    And I should not see "other"
    And I should not see "foo"
    When I fill in "q" with "mock.public.address"
    And I press "Search"
    Then I should see "mock"
    And I should not see "test"
    And I should not see "other"
    And I should not see "foo"
    When I fill in "q" with "test.private.address"
    And I press "Search"
    Then I should not see "mock"
    And I should see "test"
    And I should not see "other"
    And I should not see "foo"
    When I fill in "q" with "Doe"
    And I press "Search"
    Then I should not see "mock"
    And I should not see "test"
    And I should not see "other"
    And I should see "foo"


  Scenario: Instance with correct id is displayed when id is greater than 10
    Given there are 10 instances
    And there is a "mock1" instance
    And I am on the the instances page
    When I follow "mock1"
    Then I should see "Properties for mock1"

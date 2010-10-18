# language: en
Feature: Mange Instances
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
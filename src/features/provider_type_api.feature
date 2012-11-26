@api
Feature: Manage Provider Types via API
  As a client of conductor,
  In order to manage the full life cycle of provider types in the system
  I want to be able to Create, Update and Delete providers via a RESTful API

  Background:
    Given I am an authorised user
    And I use my authentication credentials in each request

  Scenario: Get list of provider types as XML
    Given there are some provider types
    When I request a list of provider types returned as XML
    Then I should receive list of provider types as XML

  Scenario: Get details for provider type as XML
    Given there is a provider type
    When I ask for details of that provider type as XML
    Then I should receive details of that provider type as XML

  Scenario: Get details for non existing provider type
    When I ask for details of non existing provider type
    Then I should receive Not Found error

  Scenario: Delete Provider Type
    Given there is a provider type
    When I delete that provider type via XML
    Then I should receive a No Content message
    And the provider type should be deleted

  Scenario: Attempt to delete non-existant provider type
    Given there are some provider types
    And the specified provider type does not exist in the system
    When I attempt to delete the provider type
    Then I should receive Not Found error
    And no provider type should be deleted

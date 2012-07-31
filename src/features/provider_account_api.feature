@api
Feature: Manage Provider Accounts via API
  As a client of conductor,
  In order to manage the full life cycle of provider accounts in the system
  I want to be able to Create, Update and Delete provider accounts via a RESTful API

  Background:
    Given I am an authorised user
    And I use my authentication credentials in each request
    And there is a provider

  Scenario: Get list of provider accounts for given provider as XML
    Given there are some provider accounts for given provider
    And there is another provider
    And there are some provider accounts for that another provider
    When I request a list of provider accounts for that provider returned as XML
    Then I should receive list of provider accounts for that provider as XML

  Scenario: Attempt to get list of provider accounts for non existing provider via XML
    Given the specified provider does not exist in the system
    When I request a list of provider accounts for that provider returned as XML
    Then I should receive Not Found error

  Scenario: Get details for provider account as XML
    Given there is a provider account
    When I ask for details of that provider account as XML
    Then I should receive details of that provider account as XML

  Scenario: Get details for non existing provider account
    When I ask for details of non existing provider account
    Then I should receive Not Found error

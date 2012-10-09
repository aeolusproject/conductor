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

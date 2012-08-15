@api
Feature: Manage Pools via API
  As a client of conductor,
  In order to manage the full life cycle of pools in the system
  I want to be able to Create, Update and Delete pools via a RESTful API

  Background:
    Given I am an authorised user
    And I use my authentication credentials in each request

  Scenario: Get list of pools as XML
    Given a pool "foo" exists
    And a pool "bar" exists
    When I request a list of pools as XML
    # The third pool besides foo and bar is the Default pool
    Then I should receive list of 3 pools as XML

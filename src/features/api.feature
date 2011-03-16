Feature: User authentication
  In order to automatically manage my Cloud Engine environment
  As a client
  I must be able to access a Cloud Engine APU+I

  Background:
    Given I am an authorised user
    And I am logged in
    And There is a mock pulp repository

  Scenario: Check can start instance
    Given there is a user "testuser"
    And there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And there are the following instances:
    | name  | external_key | state   | public_addresses     | private_addresses    |
    | mock  | ext_mock     | stopped | mock.public.address  | mock.private.address |
    And user "testuser" owns instance "mock"
    When a client requests "can_start" for instance "mock" for provider account "testaccount"
    Then the root element should be "result"
    And there should exist the following xpath: "/result/action_request"
    And this path should have the value "can_start"
    And there should exist the following xpath: "/result/instance_id"
    And there should exist the following xpath: "/result/value"
    And this path should have the value "true"

  Scenario: Check can create instance
    Given there is a user "testuser"
    And there is a provider named "testprovider"
    And there is a provider account named "testaccount"
    And there are the following instances:
    | name  | external_key | state   | public_addresses     | private_addresses    |
    | mock  | ext_mock     | stopped | mock.public.address  | mock.private.address |
    And user "testuser" owns instance "mock"
    When a client requests "can_create" for instance "mock" for provider account "testaccount"
    Then the root element should be "result"
    And there should exist the following xpath: "/result/action_request"
    And this path should have the value "can_create"
    And there should exist the following xpath: "/result/instance_id"
    And there should exist the following xpath: "/result/value"
    And this path should have the value "true"

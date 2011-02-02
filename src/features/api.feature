Feature: User authentication
  In order to automatically manage my Cloud Engine environment
  As a client
  I must be able to access a Cloud Engine APU+I

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Get matching profiles via API
    Given I am an authorised user
    Given there are the following provider hardware profiles:
    | name         | memory | cpu |storage  | architecture |
    | m1-small     | 1740   | 1   | 250     | i386         |
    | m1-medium    | 4096   | 4   | 850     | x86_64       |
    Given there are the following aggregator hardware profiles:
    | name       | memory | cpu |storage  | architecture |
    | agg-medium | 4096   | 4   | 850     | x86_64       |
    When a client requests matching hardware profiles for "agg-medium"
    Then the root element should be "matching_hardware_profiles"
    And there should exist the following xpath: "/matching_hardware_profiles/matching_hardware_profile/hardware_profile/name"
    And this path should have the value "m1-medium"
    And there should exist the following xpath: "/matching_hardware_profiles/matching_hardware_profile/hardware_profile/property"
    And this path should contain the following elements:
    | element  | kind  | name         | unit  | value  |
    | property | fixed | memory       | MB    | 4096   |
    | property | fixed | cpu          | count | 4      |
    | property | fixed | architecture | label | x86_64 |
    | property | fixed | storage      | GB    | 850    |
    And there should exist the following xpath: "/matching_hardware_profiles/matching_hardware_profile/constraints/property"
    And this path should contain the following elements:
    | element  | kind  | name         | unit  | value  |
    | property | fixed | memory       | MB    | 4096   |
    | property | fixed | cpu          | count | 4      |
    | property | fixed | storage      | GB    | 850    |
    | property | fixed | architecture | label | x86_64 |

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

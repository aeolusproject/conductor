#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

@api
Feature: Manage Providers via API
  As a client of conductor,
  In order to manage the full life cycle of providers in the system
  I want to be able to Create, Update and Delete providers via a RESTful API

  Background:
    Given I am an authorised user
    And I use my authentication credentials in each request

  Scenario: Get list of providers as XML
    Given there are some providers
    When I request a list of providers returned as XML
    Then I should receive list of providers as XML

  Scenario: Get details for provider as XML
    Given there is a provider
    When I ask for details of that provider as XML
    Then I should recieve details of that provider as XML

  Scenario: Get details for non existing provider
    When I ask for details of non existing provider as XML
    Then I should recieve Not Found error

#  Scenario: Create a new provider
#    When I create provider with correct data
#    Then I should recieve OK message
#    And the provider should be created
#
#  Scenario: Create a new provider with bad request
#    When I create provider with incorrect data
#    Then I should recieve Bad Request message
#    And the provider should not be created
#
#  Scenario: Update a provider
#    Given there is a provider
#    When I update that provider with correct data
#    Then I should recieve OK message
#    And the provider should be updated
#
#  Scenario: Update a provider with bad request
#    Given there is a provider
#    When I update that provider with incorrect data
#    Then I should recieve Bad Request message
#    And the provider should not be updated
#
#  Scenario: Delete Provider
#    Given there is a provider
#    When I delete that provider
#    Then I should received an OK message
#    And the provider should be deleted
#
#  Scenario: Attempt to delete non-existant provider
#    Given the specified provider does not exist in the system
#    When I attempt to delete the provider
#    Then I should receive a Provider Not Found error
#    And the provider should not be deleted

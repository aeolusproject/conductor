#
#   Copyright 2012 Red Hat, Inc.
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
Feature: Manage Catalogs via API
  As a client of conductor
  In order to manage the full life cycle of catalogs in the system
  I want to be able to Create, Read, Update and Delete catalogs via a RESTful API

  Background:
    Given I am an authorised user
    And I use my authentication credentials in each request

  @wip
  Scenario: Get list of catalogs as XML
    Given there are some catalogs
    When I request a list of catalogs returned as XML
    Then I should receive list of catalogs as XML

  @wip
  Scenario: Get details of a catalog as XML
    Given there is a catalog
    When I ask for details of that catalog as XML
    Then I should receive details of that catalog as XML

  @wip
  Scenario: Get details of non-existent catalog
    Given the specified catalog does not exist in the system
    When I ask for details of that catalog as XML
    Then I should receive Not Found error

  @wip
  Scenario: Create a new catalog
    When I create catalog with correct data via XML
    Then I should receive OK message
    And the catalog should be created

  @wip
  Scenario: Create a new catalog with bad request
    When I create catalog with incorrect data via XML
    Then I should receive Bad Request error
    And the catalog should not be created

  @wip
  Scenario: Update a catalog
    Given there is a catalog
    When I update that catalog with correct data via XML
    Then I should receive OK message
    And the catalog should be updated

  @wip
  Scenario: Update a catalog with bad request
    Given there is a catalog
    When I update that catalog with incorrect data via XML
    Then I should receive Bad Request error
    And the catalog should not be updated

  @wip
  Scenario: Attempt to update a non-existent catalog
    Given the specified catalog does not exist in the system
    When I update that catalog with correct data via XML
    Then I should receive Not Found error
    And no catalog should be updated

  @wip
  Scenario: Delete catalog
    Given there is a catalog
    When I delete that catalog via XML
    Then I should receive an OK message
    And the catalog should be deleted

  @wip
  Scenario: Attempt to delete a non-existent catalog
    Given the specified catalog does not exist in the system
    When I delete that catalog via XML
    Then I should receive Not Found error
    And no catalog should be deleted

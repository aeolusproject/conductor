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
Feature: Manage Deployments via API
  As a client of conductor
  In order to manage the full life cycle of deployments in the system
  I want to be able to Create, Read, Update and Delete deployments via a RESTful API

  Background:
    Given I am an authorised user
    And I use my authentication credentials in each request

  Scenario: Get list of deployments as XML
    Given there are some deployments
    When I request a list of deployments returned as XML
    Then I should receive list of those deployments as XML

  Scenario: Get details of a deployment as XML
    Given there is a deployment
    When I ask for details of that deployment as XML
    Then I should receive details of that deployment as XML

  Scenario: Get details of non-existent deployment
    Given the specified deployment does not exist in the system
    When I ask for details of that deployment as XML
    Then I should receive Not Found error

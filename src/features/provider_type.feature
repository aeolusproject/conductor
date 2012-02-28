Feature: Manage Providers
  In order to manage my cloud infrastructure
  As a user
  I want to manage cloud providers

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List providers in XML format
    Given I accept XML
    When I go to the provider types page
    Then I should get a XML document
    And there should be these provider types:
    | name         | deltacloud_driver    |
    | Mock         | mock                 |
    | Amazon EC2   | ec2                  |
    | RHEV-M       | rhevm                |
    | VMware vSphere | vsphere            |
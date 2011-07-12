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
    | name         | codename    |
    | Mock         | mock        |
    | GoGrid       | gogrid      |
    | Rackspace    | rackspace   |
    | OpenNebula   | opennebula  |
    | Amazon EC2   | ec2         |
    | RHEV-M       | rhevm       |
    | Condor Cloud   | condorcloud |
    | VMware vSphere | vsphere     |
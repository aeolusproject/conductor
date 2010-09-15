Feature: Manage Templates
  In order to manage my cloud infrastructure
  As a user
  I want to manage templates

  Background:
    Given I am an authorised user
    And I am logged in
    And There is a mock pulp repository

  Scenario: Add basic info to a new Template
    Given I am on the homepage
    When I follow "Create a Template"
    Then I should be on the new template page
    And I should see "Create a New Template"
    When I fill in the following:
      | xml_name         | mocktemplate  |
      | xml_platform     | rhel          |
      | xml_description  | mockdesc      |
    And I press "Next"
    Then I should be on the template services page
    And I should have a template named "mocktemplate"

  Scenario: Add a package to the template
    Given There is a "mocktemplate" template
    And I am on the template software page
    And there is a package group
    And no package is selected
    When I follow "Select" within ".selection_list"
    Then I should see "Remove" within "#selected_packages"

  Scenario: Remove a package from the template
    Given There is a "mocktemplate" template
    And there is one selected package
    And I jump on the "mocktemplate" template software page
    When I follow "Remove" within "#selected_packages"
    Then I should not see "Remove" within "#selected_packages"

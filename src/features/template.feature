Feature: Manage Templates
  In order to manage my cloud infrastructure
  As a user
  I want to manage templates

  Background:
    Given I am an authorised user
    And I am logged in
    And There is a mock pulp repository

  Scenario: Create a new Template
    Given I am on the templates page
    When I follow "Template"
    Then I should be on the new template page
    When I fill in the following:
      | tpl_name         | mocktemplate  |
      | tpl_platform     | fedora        |
      | tpl_platform     | 11            |
      | tpl_summary      | mockdesc      |
    When I press "Save"
    Then I should be on the templates page
    And I should see "Template saved"
    And I should see "mocktemplate"

  Scenario: Add/Remove a package and a group to/from the template
    Given I am on the templates page
    When I follow "Template"
    Then I should be on the new template page
    When I fill in the following:
      | tpl_name         | mocktemplate  |
    And I press "select_package_jboss-as5"
    Then I should be on the create template page
    And the "tpl[name]" field by name should contain "mocktemplate"
    And the page should contain "#selected_package_jboss-as5" selector
    When I press "remove_package_jboss-as5"
    Then I should be on the create template page
    And the page should not contain "#selected_package_jboss-as5" selector
    When I press "select_group_JBoss Core Packages"
    Then I should be on the create template page
    And the "tpl[name]" field by name should contain "mocktemplate"
    And the page should contain "#selected_package_jboss-jgroups" selector
    When I press "Save"
    Then I should be on the templates page
    And I should see "Template saved"
    And I should see "mocktemplate"

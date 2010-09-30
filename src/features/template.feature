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
    When I press "Template"
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

  Scenario: Add group and remove package to/from the template
    Given I am on the templates page
    When I press "Template"
    Then I should be on the new template page
    When I fill in the following:
      | tpl_name         | mocktemplate  |
    And I press "Add Software"
    Then I should see "Managed Content Selection"
    When I check "group_JBoss_Core_Packages"
    And I press "Add Selected"
    Then I should see "Managed Content to Bundle"
    And the "tpl[name]" field by name should contain "mocktemplate"
    And the page should contain "#selected_package_jboss-as5" selector
    When I press "remove_package_jboss-as5"
    Then I should see "Managed Content to Bundle"
    And the page should not contain "#selected_package_jboss-as5" selector
    When I press "Save"
    Then I should be on the templates page
    And I should see "Template saved"
    And I should see "mocktemplate"

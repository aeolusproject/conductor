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
    When I follow "Create"
    Then I should be on the new template page
    When I fill in the following:
      | tpl_name         | mocktemplate  |
      | tpl_platform     | fedora13      |
      | tpl_summary      | mockdesc      |
    When I press "Save"
    Then I should be on the templates page
    And I should see "Template saved"
    And I should see "mocktemplate"

  Scenario: Add a package to a new template
    Given I am on the new template page
    When I press "Add Software"
    When I press "admin-tools"
    Then I should see "System Tools"
    And I should see "libdeltacloud"
    When I check "libdeltacloud"
    And I press "Add Selected"
    Then I should see "New Template"
    And I should see "libdeltacloud"

  Scenario: Add a searched package to a new template
    Given I am on the new template page
    When I press "Add Software"
    And I fill in "package_search" with "libdeltacloud"
    And I press "package_search_button"
    Then I should see "libdeltacloud"
    When I check "libdeltacloud"
    And I press "Add Selected"
    Then I should see "New Template"
    And I should see "libdeltacloud"

  Scenario: Add group and remove package to/from the template
    Given I am on the templates page
    When I follow "Create"
    Then I should be on the new template page
    When I fill in the following:
      | tpl_name         | mocktemplate  |
    And I press "Add Software"
    Then I should see "Managed Content Selection"
    When I press "Collections"
    And I check "group_system-tools"
    And I press "Add Selected"
    Then I should see "Managed Content to Bundle"
    And the "tpl[name]" field by name should contain "mocktemplate"
    And the page should contain "#package_libdeltacloud" selector
    When I press "remove_package_libdeltacloud"
    Then I should see "Managed Content to Bundle"
    And the page should not contain "#package_libdeltacloud" selector
    When I press "Save"
    Then I should be on the templates page
    And I should see "Template saved"
    And I should see "mocktemplate"

  Scenario: Add group of packages to existing template
    Given there is a "mock1" template
    And has package "deltacloud-aggregator"
    When I edit the template
    And I press "Add Software"
    Then I should see "Managed Content Selection"
    When I press "Collections"
    And I check "group_system-tools"
    And I press "Add Selected"
    Then I should see "Managed Content to Bundle"
    And the page should contain "#package_libdeltacloud" selector
    When I press "Save"
    Then I should be on the templates page
    And I should see "Template updated"
    When I edit the template
    Then the page should contain "#package_libdeltacloud" selector

  Scenario: Sorting templates
    Given there is a "mock1" template
    And there is a "mock2" template
    And I am on the templates page
    When I follow "Name" within "#templates_table"
    Then I should see "mock1" followed by "mock2"
    When I follow "Name" within "#templates_table"
    Then I should see "mock2" followed by "mock1"

  Scenario: Sorting template builds
    Given there is a "mock1" build
    And there is a "mock2" build
    And I am on the template builds page
    When I follow "Name"
    Then I should see "mock1" followed by "mock2"
    When I follow "Name"
    Then I should see "mock2" followed by "mock1"

  Scenario: Search software with empty string
    Given I am on the new template page
    When I press "Add Software"
    And I fill in "package_search" with ""
    And I press "package_search_button"
    Then I should see "Search string is empty"

  Scenario: Show software selection
    Given I am on the new template page
    And I press "Add Software"
    Then I should see an input "Collections"
    # test that we see a metagroup
    Then I should see an input "admin-tools"
    # test that we see a collection (collections are loaded by default)
    And I should see an input "system-tools"

  Scenario: See upload status
    Given there is a "mock1" template
    And there is Amazon AWS build and push for this template
    And I am on the templates page
    When I choose this template
    And I follow "Builds"
    Then I should see "amazon-ec2: complete"

  Scenario: Build template
    Given there is a "mock1" template
    And there is Amazon AWS provider account
    And I am on the templates page
    When I choose this template
    And I follow "Builds"
    Then I should see "Builds for"
    When I select "Amazon EC2" from "target"
    And I press "Go"
    Then I should be on the template page
    And I should see "mock1"

  Scenario: Upload image
    Given there is a "mock1" template
    And I am on the templates page
    And there is Amazon AWS build for this template
    And there is Amazon AWS provider
    And I am on the templates page
    When I choose this template
    And I follow "Builds"
    Then I should see "amazon-ec2: not uploaded upload"
    When I follow "upload"
    Then I should see "Builds"
    # TODO: fix status once uploaded field is replaced by status field
    And I should see "amazon-ec2: queued"

  Scenario: Build imported template
    Given there is an imported template
    And there is Amazon AWS provider account
    And I am on the templates page
    When I choose this template
    And I follow "Builds"
    Then I should see "Build imported template is not supported"

  Scenario: Search for templates
    Given there are these templates:
    | name          | platform | platform_version | architecture | summary                                       |
    | Test1         | fedora13   | 13               | x86_64       | Test Template Fedora 13  64 bit  Description  |
    | Mock          | fedora14   | 14               | i386         | Test Template Fedora 14 Description           |
    | Other         | fedora14   | 10.04            | i386         | Test Template Ubuntu 10.04 32 bit Description |
    And I am on the templates page
    Then I should see the following:
    | NAME          | OS       | VERSION          | ARCH   |
    | Test1         | Fedora   | 13               | x86_64 |
    | Mock          | Fedora   | 14               | i386   |
    | Other         | Fedora   | 10.04            | i386   |
    When I fill in "q" with "test"
    And I press "Search"
    Then I should see "Test1"
    And I should see "Mock"
    And I should see "Other"
    When I fill in "q" with "Mock"
    And I press "Search"
    Then I should see "Mock"
    And I should not see "Test1"
    And I should not see "Other"
    When I fill in "q" with "13"
    And I press "Search"
    Then I should see "Test1"
    And I should not see "Other"
    And I should not see "Mock"
    When I fill in "q" with "x86_64"
    And I press "Search"
    Then I should see "Test1"
    And I should not see "Other"
    And I should not see "Mock"
    When I fill in "q" with "fedora"
    And I press "Search"
    Then I should see "Test1"
    And I should see "Other"
    And I should see "Mock"
    When I fill in "q" with "32 bit Description"
    And I press "Search"
    Then I should not see "Test1"
    And I should see "Other"
    And I should not see "Mock"

  Scenario: Delete multiple templates
    Given there are these templates:
    | name          | platform | platform_version | architecture | summary                                       |
    | Test1         | fedora13   | 13               | x86_64       | Test Template Fedora 13  64 bit  Description  |
    | Mock          | fedora13   | 14               | i386         | Test Template Fedora 14 Description           |
    | Other         | fedora13   | 10.04            | i386         | Test Template Ubuntu 10.04 32 bit Description |
    And I am on the templates page
    When I check "Test1" template
    And I check "Mock" template
    And I press "Delete"
    Then I should be on the templates page
    And I should see "Other"

    Scenario: Create Assembly and Deployable
      Given I am on the new template page
      When I fill in the following:
        | tpl_name         | mocktemplate  |
        | tpl_platform     | fedora13      |
        | tpl_summary      | mockdesc      |
      And I check "create_deployable"
      And I press "Save"
      Then I should be on the templates page
      And I should see "mocktemplate"
      When I go to the deployables page
      And I should see "mocktemplate"

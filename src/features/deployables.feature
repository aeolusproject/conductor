Feature: Manage Catalog Entries
  In order to manage catalog entries
  As an admin
  I want to add/edit/remove catalog entries

  Background:
    Given I am an authorised user
    And I am logged in
    And there is mock provider account "mock_account"

  Scenario: Create new catalog entry
    Given there is a "default" catalog
    When I am on the "default" catalog catalog entries page
    Then I should see "Deployables"
    When I follow "new_catalog_entry_button"
    Then I should see "Add New Deployable"
    When I fill in "deployable[name]" with "test1"
    And I fill in "deployable[description]" with "description"
    When I attach the file "features/upload_files/deployable.xml" to "deployable[xml]"
    And I press "save_button"
    Then I should see "Deployable added"

  Scenario: Change the name
    Given there is a "default" catalog
    And a catalog entry "testdepl" exists for "default" catalog
    When I am on the "default" catalog catalog entries page
    When I follow "testdepl"
    And I follow "edit_button"
    Then I should see "Editing Deployable"
    When I fill in "deployable[name]" with "testdepl-renamed"
    And I press "save_button"
    Then I should see "Deployable updated successfully!"
    And I should see "testdepl-renamed"

  Scenario: Show catalog entry details
    Given there is a "default" catalog
    And a catalog entry "testdepl" exists for "default" catalog
    And I am on the "default" catalog catalog entries page
    When I follow "testdepl"
    Then I should see "testdepl"
    And I should be on testdepl's catalog entry page

  Scenario: Launch a deployment
    Given there is a "default" catalog
    And a catalog entry "testdepl" exists for "default" catalog
    And there is "front_hwp1" conductor hardware profile
    And there is "front_hwp2" conductor hardware profile
    And I am on testdepl's catalog entry page
    When I follow "launch_deployment_button"
    Then I should be on the launch time params deployments page

  Scenario: Delete deployables
    Given there is a "default" catalog
    And a catalog entry "testdepl1" exists for "default" catalog
    And a catalog entry "testdepl2" exists for "default" catalog
    And I am on the "default" catalog catalog entries page
    When I check "testdepl1" catalog entry
    And I check "testdepl2" catalog entry
    And I press "delete_button"
    Then I should be on the "default" catalog page
    And there should be only 0 catalog entries for "default" catalog
    And I should see "2 deployables testdepl1, testdepl2 were deleted!"

  Scenario: Delete deployable
    Given there is a "default" catalog
    And a catalog entry "testdepl1" exists for "default" catalog
    And I am on the "default" catalog page
    When I follow "testdepl1"
    And I press "delete"
    Then I should be on the "default" catalog page
    And there should be only 0 catalog entries for "default" catalog
    And I should see "Deployable testdepl1 delete successfully!"

  #Scenario: Search Catalog Entries
  #  Given there is a "testcatalog" catalog
  #  And a catalog entry "mycatalog_entry" exists
  #  And a catalog entry "somecatalog_entry" exists
  #  And I am on the "testcatalog" catalog catalog entries page
  #  Then I should see "mycatalog_entry"
  #  And I should see "somecatalog_entry"
  #  When I fill in "catalog_entries_search" with "some"
  #  And I press "apply_catalog_entries_search"
  #  Then I should see "somecatalog_entry"
  #  And I should not see "mycatalog_entry"
  #  When I fill in "catalog_entries_search" with "mycatalog_entry"
  #  And I press "apply_catalog_entries_search"
  #  Then I should see "mycatalog_entry"
  #  And I should not see "somecatalog_entry"

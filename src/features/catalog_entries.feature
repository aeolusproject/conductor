Feature: Manage Catalog Entries
  In order to manage catalog entries
  As an admin
  I want to add/edit/remove catalog entries

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Create new catalog entry
    Given there is a "default" catalog
    When I am on the "default" catalog catalog entries page
    When I follow "new_catalog_entry_button"
    Then I should see "Add New Catalog Entry"
    When I fill in "catalog_entry[name]" with "test1"
    And I fill in "catalog_entry[description]" with "description"
    When I attach the file "features/upload_files/deployable.xml" to "catalog_entry[xml]"
    And I press "save_button"
    Then I should see "Catalog entry added"

  Scenario: Change the name
    Given there is a "default" catalog
    And a catalog entry "testdepl" exists
    When I am on the "default" catalog catalog entries page
    When I follow "testdepl"
    And I follow "edit_button"
    Then I should see "Editing Catalog Entry"
    When I fill in "catalog_entry[name]" with "testdepl-renamed"
    And I press "save_button"
    Then I should see "Catalog entry updated successfully!"
    And I should see "testdepl-renamed"

  Scenario: Show catalog entry details
    Given there is a "default" catalog
    And a catalog entry "testdepl" exists
    And I am on the "default" catalog catalog entries page
    When I follow "testdepl"
    Then I should see "testdepl"
    And I should see "Name"
    And I should see "description"
    And I should see "Deployable XML"

  Scenario: Delete deployables
    Given there is a "default" catalog
    And a catalog entry "testdepl1" exists for "default" catalog
    And a catalog entry "testdepl2" exists for "default" catalog
    And I am on the "default" catalog catalog entries page
    When I check "testdepl1" catalog entry
    And I check "testdepl2" catalog entry
    And I press "delete_button"
    Then there should be only 0 catalog entries
    And I should be on the "default" catalog page
    And I should not see "testdepl1"
    And I should not see "testdepl2"

  Scenario: Delete deployable
    Given there is a "default" catalog
    And a catalog entry "testdepl1" exists for "default" catalog
    And I am on the "default" catalog page
    When I follow "testdepl1"
    And I press "delete"
    Then there should be only 0 catalog entries
    And I should be on the "default" catalog page
    And I should not see "testdepl1"

Feature: Manage Catalogs
  In order to manage catalogs
  As an admin
  I want to be able to perform CRUD operations on catalogs

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Create a new catalog
    Given I am on the catalogs page
    And a pool "default" exists
    And I follow "new_catalog_button"
    Then I should see "Add New Catalog"
    And I fill in "catalog_name" with "Finance"
    And I select "default" from "catalog_pool_id"
    And I press "Save"
    Then I should be on the catalogs page
    And I should see "Finance"

  Scenario: Show catalog details
    Given there is a "Marketing" catalog
    And I am on the catalogs page
    When I follow "Marketing"
    Then I should see "Name: Marketing"

  Scenario: Edit a catalog
    Given there is a "Development" catalog
    And I am on the catalogs page
    When I follow "Development"
    And I follow "edit_button"
    And I fill in "Engineering" for "catalog[name]"
    And I press "Save"
    Then I should be on the catalogs page
    And I should see "Engineering"
    And I should not see "Development"

  Scenario: Delete a catalog
    Given there is a "Bad" catalog
    And I am on the catalogs page
    When I follow "Bad"
    And I press "delete"
    Then I should be on the catalogs page
    And I should not see "Bad"
    And I should see "Catalog deleted!"

  Scenario: Delete multiple catalogs
    Given there is a "bad" catalog
    And there is a "worse" catalog
    And I am on the catalogs page
    When I check "bad" catalog
    And I check "worse" catalog
    And I press "delete_button"
    Then I should be on the catalogs page
    And I should see "2 catalogs bad, worse deleted!"

  Scenario: Search catalogs
    Given there is a "mycatalog" catalog
    And there is a "somecatalog" catalog
    And I am on the catalogs page
    Then I should see "mycatalog"
    And I should see "somecatalog"
    When I fill in "catalogs_search" with "some"
    And I press "apply_catalogs_search"
    Then I should see "somecatalog"
    And I should not see "mycatalog"
    When I fill in "catalogs_search" with "mycatalog"
    And I press "apply_catalogs_search"
    Then I should see "mycatalog"
    And I should not see "somecatalog"

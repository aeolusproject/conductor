Feature: Manage Permissions
  In order to manage permissions
  As an admin
  I want to add/remove a permission for a user

  Background:
    Given I am an authorised user
    And I am logged in
    And a user "testuser" exists
    And a pool "PermissionPool" exists

  Scenario: Create a new Permission
    Given I am viewing the pool "PermissionPool"
    When I follow link with ID "details_permissions"
    And there is not a permission for the user "testuser"
    When I follow "Grant Access"
    Then I should be on the new permission page
    And I should see "Choose roles for users"
    When I select "Zone User" role for the user "testuser"
    And I press "Grant Access"
    Then I should be on the page for the pool "PermissionPool"
    And I should see "Added the following User Roles"
    And I should see "testuser"

  Scenario: Create a second permission on a resource
    Given there is a permission for the user "testuser" on the pool "PermissionPool"
    And I am viewing the pool "PermissionPool"
    When I follow link with ID "details_permissions"
    When I follow "Grant Access"
    Then I should be on the new permission page
    And I should see "Choose roles for users"
    When I select "Zone Administrator" role for the user "testuser"
    And I press "Grant Access"
    Then I should be on the page for the pool "PermissionPool"
    And I should see "Added the following User Roles"
    And I should see "testuser"

  Scenario: Attempt to duplicate a permission
    Given there is a permission for the user "testuser" on the pool "PermissionPool"
    And I am viewing the pool "PermissionPool"
    When I follow link with ID "details_permissions"
    When I follow "Grant Access"
    Then I should be on the new permission page
    And I should see "Choose roles for users"
    When I select "Zone User" role for the user "testuser"
    And I press "Grant Access"
    Then I should be on the page for the pool "PermissionPool"
    And I should see "Could not add these User Roles"
    And I should see "testuser"

  Scenario: Delete a permission
    Given there is a permission for the user "testuser" on the pool "PermissionPool"
    And I am viewing the pool "PermissionPool"
    When I follow link with ID "details_permissions"
    When I delete the permission
    Then I should be on the page for the pool "PermissionPool"
    And I should see "Deleted the following Permission Grants"

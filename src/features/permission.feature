Feature: Manage Permissions
  In order to manage permissions
  As an admin
  I want to add/remove a permission for a user

  Background:
    Given I am an authorised user
    And I am logged in
    And a user "testuser" exists

  Scenario: Create a new Permission
    Given I am on the permissions page
    And there is not a permission for the user "testuser"
    When I follow "Add a new permission record"
    Then I should be on the new permission page
    And I should see "new Permission"
    When I select "testuser" from "permission[user_id]"
    And I select "Provider Creator" from "permission[role_id]"
    And I press "Save"
    Then I should be on the permissions page
    And I should see "Permission record added"
    And I should see "testuser"

  Scenario: Create a permission which already exists
    Given there is a permission for the user "testuser"
    And I am on the new permission page
    When I select "testuser" from "permission[user_id]"
    And I select "Provider Creator" from "permission[role_id]"
    And I press "Save"
    Then I should see "new Permission"

  Scenario: Delete a permission
    Given there is a permission for the user "testuser"
    And I am on the permissions page
    When I delete the permission
    Then I should be on the permissions page

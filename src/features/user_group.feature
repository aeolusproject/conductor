Feature: Manage User Groups
  In order to manage user groups
  As an admin
  I want to add/edit/remove user groupss

  Background:
    Given I am an authorised user
    And I am logged in
    And a user group "testgroup" exists
    And a user "testuser" exists

  Scenario: Show user group detials
    Given I am on the user groups page
    And there is a user group "testgroup"
    When I follow "testgroup"
    Then I should be on testgroup's user group page

  Scenario: Show user group permissions
    Given a pool "PermissionPool" exists
    And there is a permission for the user group "testgroup" on the pool "PermissionPool"
    And I am on the user groups page
    When I follow "testgroup"
    Then I should see "PermissionPool"

  Scenario: Delete user groups
    Given there is a user group "testgroup"
    Given there is a user group "testgroup2"
    And I am on the user groups page
    Then there should be 2 user groups
    And I should be on the user groups page
    When I check "testgroup" user group
    And I press "Delete"
    Then I should see "Deleted user group"
    And there should be 1 user group

  Scenario: Create new user group
    Given I am on the user groups page
    When I follow "add_user_group_button"
    Then I should be on the new user group page
    And I should see "New User Group"
    When I select "Local" from "Membership source"
    And I fill in the following:
      | Name  | testgroup3             |
    And I press "Create User Group"
    Then I should be on the user groups page
    And I should see "User Group added"

  Scenario: Edit existing user group
    Given I am on the user groups page
    And I follow "testgroup"
    Then I should be on testgroup's user group page
    And I should see "testgroup"
    When I follow "Edit"
    Then I should be on the testgroup's edit user group page
    And I fill in "user_group_name" with "newname"
    When I press "Update User Group"
    Then I should be on newname's user group page
    And I should see "User Group updated"
    And I should see "newname"

  Scenario: Add member to user group
    Given I am on the user groups page
    And I follow "testgroup"
    Then I should be on testgroup's user group page
    And I should see "testgroup"
    When I follow "Add Member"
    And I check the "testuser" member
    And I press "Add Member"
    Then there should be 1 user belonging to "testgroup"
    And I should see "testuser"

  Scenario: Remove member from user group
    And there is a user "testuser" belonging to user group "testgroup"
    Given I am on the user groups page
    And I follow "testgroup"
    Then I should be on testgroup's user group page
    Then I should see "testuser"
    When I check the "testuser" member
    And I press "Remove"
    Then there should not exist a member belonging to "testgroup"

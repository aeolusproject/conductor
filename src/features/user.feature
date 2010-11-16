Feature: Manage Users
  In order to manage users
  As an admin
  I want to add/edit/remove users

  Background:
    Given I am an authorised user
    And I am logged in
    And a user "testuser" exists

  Scenario: Change the password
    Given I am on the users page
    And there is a user "testuser"
    When I follow "testuser"
    Then I should see "Editing User:"
    When I fill in "user[password]" with "new password"
    And I fill in "user[password_confirmation]" with ""
    And I press "Save"
    Then I should see "Password doesn't match confirmation"
    When I fill in "user[password]" with ""
    And I fill in "user[password_confirmation]" with "new password"
    And I press "Save"
    Then I should see "Password doesn't match confirmation"
    When I fill in "user[password]" with "new password"
    And I fill in "user[password_confirmation]" with "new password"
    And I press "Save"
    Then I should see "User updated!"

  Scenario: Administrator cancels the creation of a user account
    Given I am on the users page
    And there are 2 users
    When I follow "create"
    Then I should be on the new user page
    When I follow "cancel"
    Then there should only be 2 users
    And I should be on the users page

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
    And I follow "Edit"
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

  Scenario: Show user detials
    Given I am on the users page
    And there is a user "testuser"
    When I follow "testuser"
    Then I should be on testuser's user page

  Scenario: Administrator cancels the creation of a user account
    Given I am on the users page
    And there are 2 users
    When I follow "New User"
    Then I should be on the new user page
    When I follow "cancel"
    Then there should be 2 users
    And I should be on the users page

  Scenario: Delete users
    Given there is a user "testuser"
    And I am on the users page
    Then there should be 2 users
    When I check "admin" user
    And I press "Delete"
    Then I should see "Cannot delete admin"
    And there should be 2 users
    And I should be on the users page
    When I check "testuser" user
    And I press "Delete"
    Then I should see "Deleted user"
    And there should be 1 user

  Scenario: Create new user
    Given I am on the users page
    When I follow "New User"
    Then I should be on the new user page
    And I should see "New Account"
    When I fill in the following:
      | Choose a username | testuser2             |
      | Choose a password | secret                |
      | Confirm password  | secret                |
      | First name        | Joe                   |
      | Last name         | Tester                |
      | E-mail            | testuser2@example.com |
    And I press "Save"
    Then I should be on the users page
    And I should see "User registered!"

  Scenario: Want to register new user but decide to cancel
    Given I am on the users page
    When I follow "New User"
    Then I should be on the new user page
    And I should see "New Account"
    When I fill in the following:
      | Choose a username | testuser2             |
      | Choose a password | secret                |
      | Confirm password  | secret                |
      | First name        | Joe                   |
      | Last name         | Tester                |
      | E-mail            | testuser2@example.com |
    And I follow "Cancel"
    Then I should be on the users page
    And there should not be user with login "canceluser"

  Scenario: Edit existing user
    Given I am on the users page
    And I follow "testuser"
    Then I should be on testuser's user page
    And I should see "John"
    When I follow "Edit"
    Then I should be on the testuser's edit user page
    And I fill in "user_first_name" with "Joe"
    When I press "Save"
    Then I should be on testuser's user page
    And I should see "User updated!"
    And I should see "Joe"

  Scenario: Display failed login count
    Given there is a user "test"
    And I log out
    When I fill login "test" and incorrect password
    Then I should see "Login failed"
    When I login as authorised user
    And I go to test's user page
    Then "test" user failed login count is more than zero


#  Scenario: Search for users
#    Given there is a user "myuser"
#    And there is a user "someuser"
#    And I am on the users page
#    Then I should see "myuser"
#    And I should see "someuser"
#    When I fill in "q" with "some"
#    And I press "Search"
#    Then I should see "someuser"
#    And I should not see "myuser"
#    When I fill in "q" with "myuser"
#    And I press "Search"
#    Then I should see "myuser"
#    And I should not see "someuser"

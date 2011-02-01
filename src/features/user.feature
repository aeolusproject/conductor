Feature: Manage Users
  In order to manage users
  As an admin
  I want to add/edit/remove users

  Background:
    Given I am an authorised user
    And I am logged in
    And a user "testuser" exists

  Scenario: Change the password
    Given I am on the admin users page
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
    Given I am on the admin users page
    And there is a user "testuser"
    When I follow "testuser"
    Then I should be on testuser's user page

  Scenario: Administrator cancels the creation of a user account
    Given I am on the admin users page
    And there are 2 users
    When I follow "create"
    Then I should be on the new admin user page
    When I follow "cancel"
    Then there should only be 2 users
    And I should be on the admin users page

  Scenario: Search for hardware profiles
    Given there is a user "myuser"
    And there is a user "someuser"
    And I am on the admin users page
    Then I should see "myuser"
    And I should see "someuser"
    When I fill in "q" with "some"
    And I press "Search"
    Then I should see "someuser"
    And I should not see "myuser"
    When I fill in "q" with "myuser"
    And I press "Search"
    Then I should see "myuser"
    And I should not see "someuser"

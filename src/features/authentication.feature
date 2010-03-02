Feature: User authentication
  In order to access the site
  As a user
  I must register and log in

  Scenario: Register as new user
    Given I am on the homepage
    When I follow "Register"
    Then I should be on the new account page
    When I fill in the following:
      | login | testuser |
      | email    | testuser@example.com |
      | password | secret |
      | password confirmation | secret |
    And I press "Register"
    Then I should be on the account page
    And I should see "User registered!"

  Scenario: Log in as registered user
    Given I am a registered user
    And I am on the login page
    When I login
    Then I should see "Login successful!"
    And I should be on the account page

  Scenario: Log in without password
    Given I am a registered user
    And I am on the login page
    When I forget to enter my password
    Then I should see "Password cannot be blank"
    And I should be on the login error page

  Scenario: Edit profile
    Given I am logged in
    And I am on the homepage
    When I want to edit my profile
    And I follow "Edit"
    Then I should see "Edit My Profile"
    When I fill in "email" with "changed@example.com"
    And I press "Update"
    Then I should be on the account page
    And I should see "User updated!"

  Scenario: log out
    Given I am logged in
    And I am on the homepage
    When I follow "Log out"
    Then I should be logged out
    And I should see "Logout successful!"
    And I should see "Register"
    And I should see "Login"

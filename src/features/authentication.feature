Feature: User authentication
  In order to access the site
  As a user
  I must register and log in

  @register
  Scenario: Register as new user
    Given I am on the homepage
    When I follow "Create one now"
    Then I should be on the new account page
    And I should see "New Account"
    When I fill in the following:
      | Choose a username | testuser             |
      | Choose a password | secret               |
      | Confirm password  | secret               |
      | First name        | Joe                  |
      | Last name         | Tester               |
      | E-mail            | testuser@example.com |
    And I press "Save"
    Then I should be on the dashboard page

  Scenario: Want to register new user but decide to cancel
    Given I am on the homepage
    When I follow "Create one now"
    Then I should be on the new account page
    And I should see "New Account"
    When I fill in the following:
      | Choose a username | canceleduser         |
      | Choose a password | secret               |
      | Confirm password  | secret               |
      | First name        | Joe                  |
      | Last name         | Tester               |
      | E-mail            | testuser@example.com |
    And I follow "Cancel"
    Then I should be on the login page
    And there should not be user with login "canceluser"

  Scenario: Log in as registered user
    Given I am a registered user
    And I am on the login page
    When I login
    And I should be on the home page

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
    Then should see "Editing Account"
    When I fill in "E-mail" with "changed@example.com"
    And I press "Save"
    Then I should be on the dashboard page
    And I should see "User updated!"

  Scenario: log out
    Given I am logged in
    And I am on the homepage
    When I follow "Log out"
    Then I should be logged out
    And I should see "Logout successful!"
    And I should see "Create one now."
    And I should see "Log In"

  Scenario: Change user login to one with invalid length
    Given I am logged in
    And I am on the homepage
    When I want to edit my profile
    Then should see "Editing Account"
    When I enter a string of length "101" into "user[login]"
    And I press "Save"
    Then I should see "Login is too long (maximum is 100 characters)"
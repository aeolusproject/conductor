Feature: User authentication
  In order to access the site
  As a user
  I must register and log in

  Scenario: Log in as registered user
    Given I am a registered user
    And I am on the login page
    When I login
    And I should be on the home page

  Scenario: Log in without password
    Given I am a registered user
    And I am on the login page
    When I forget to enter my password
    Then I should see "Login failed"
    And I should be on the login error page

  Scenario: Edit profile
    Given I am logged in
    And I am on the root page
    When I want to edit my profile
    Then should see "Editing Account"
    When I fill in "E-mail" with "changed@example.com"
    And I press "Save"
    Then I should be on the root page
    And I should see "User updated!"

  Scenario: log out
    Given I am logged in
    And I am on the root page
    When I follow "Log out"
    Then I should be logged out
    And I should see "Username:"
    And I should see "Password:"
    And I should see "Show my password"

  Scenario: Change user login to one with invalid length
    Given I am logged in
    And I am on the root page
    When I want to edit my profile
    Then should see "Editing Account"
    When I enter a string of length "101" into "user[login]"
    And I press "Save"
    Then I should see "Login is too long (maximum is 100 characters)"

  Scenario: Log in incorrect details
    Given I am a registered user
    And I am on the login page
    When I login with incorrect credentials
    Then I should see "Login failed"
    And I should be on the login error page

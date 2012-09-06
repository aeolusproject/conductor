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
    Then I should see "The Username or Password is incorrect"
    And I should be on the login error page

  Scenario: Edit profile
    Given I have successfully logged in
    And I am on the root page
    When I want to edit my profile
    Then should see "Edit Account"
    When I fill in "E-mail" with "changed@example.com"
    And I press "Save"
    Then I should be on the my user page
    And I should see "User updated"

  Scenario: log out
    Given I am an authorised user
    And I am logged in
    And I am on the root page
    When I follow "Log Out"
    Then I should see "Username"
    And I should see "Password"
    And I should see "Forgot Login or Password?"

  Scenario: Change user login to one with invalid length
    Given I am a registered user
    And I am logged in
    And I am on the root page
    When I want to edit my profile
    Then should see "Edit Account"
    When I enter a string of length "101" into "user[login]"
    And I press "Save"
    Then I should see "Login is too long (maximum is 100 characters)"

  Scenario: Log in incorrect details
    Given I am a registered user
    And I am on the login page
    When I login with incorrect credentials
    Then I should see "The Username or Password is incorrect"
    And I should be on the login error page

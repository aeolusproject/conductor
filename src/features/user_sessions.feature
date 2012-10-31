Feature: User sessions
  In order to access the site
  As a user
  I must first log in

  Scenario: Accessing page without logging in redirects to login page
    When I visit the images page
    Then I should be on the login page

  Scenario: Login returns user to previous page
    Given I visit the images page
    And I login
    Then I should be on the images page

  Scenario: Retrieve forgotten username
    Given there is a user "admin"
    And I am on the login page
    And I follow "username_link"
    Then I should have the following query string:
      | card | username_recovery |
    And I should see "Username unknown?"
    And I fill in "email" with "admin@example.com"
    And I press "Recover Usernames"
    Then I should see "Usernames have been sent to given e-mail address."

  Scenario: Request for the forgotten password reset
    Given there is a user "admin"
    And I am on the login page
    And I follow "password_link"
    Then I should have the following query string:
      | card | password_reset |
    And I should see "Forgot your password?"
    And I fill in "username" with "admin"
    And I fill in "email" with "admin@example.com"
    And I press "Reset Password"
    Then I should see "Instructions for resetting your password have been emailed."

  Scenario: Change password using the reset token from email
    Given there is a user "admin"
    And user "admin" has valid password reset token "some_random_string"
    When I go to the password reset page with token "some_random_string"
    Then I should see "Change Password"
    When I fill in "password_field" with "my_new_password"
    And I fill in "confirm_field" with "my_new_password"
    And I press "Change Password"
    Then I should see "Password has been successfuly reset. Please log in."

  Scenario: I passwords don't match when changing password with reset token
    Given there is a user "admin"
    And user "admin" has valid password reset token "some_random_string"
    When I go to the password reset page with token "some_random_string"
    Then I should see "Change Password"
    When I fill in "password_field" with "my_new_password"
    And I fill in "confirm_field" with "my_new_different_password"
    And I press "Change Password"
    And I should see "Password doesn't match confirmation"

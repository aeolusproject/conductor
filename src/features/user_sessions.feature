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
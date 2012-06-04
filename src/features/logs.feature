Feature: View Logs
  In order to manage my cloud infrastructure
  As a user
  I want to view logs

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: View logs
    Given there is a deployment named "Test-Deployment" belonging to "Databases" owned by "bob"
    And deployement "Test-Deployment" has associated event "testevent"
    And I am on the logs page
    Then I should see "created"
    When I select "stopped" from "state"
    And I press "apply_logs_filter"
    Then I should not see "created"

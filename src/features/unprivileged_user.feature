Feature: Unprivileged user
  As a user with limited privileges
  I should not have access to privileged data

  Background:
    And I am a registered user
    And I am logged in

  Scenario: List pool families as unprivileged user
    Given  there is a pool family named "hiddenpoolfamily"
    And I can view pool family "testpoolfamily"
    When I go to the pool families page
    Then I should not see "hiddenpoolfamily"
    Then I should see "testpoolfamily"

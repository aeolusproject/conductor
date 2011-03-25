Feature: Error Handling
  In order to order to perform operations upon site objects
  As a user
  I must be able to correctly view any object errors

  Background:
    Given I am an authorised user
    And I am logged in

  @allow-rescue
  Scenario: Display Record Not Found error for a deleted object
    Given there are the following conductor hardware profiles:
    | name      | memory | cpu |storage  | architecture |
    | m1-small  | 1740   | 2   | 160     | i386         |
    | m1-large  | 4096   | 4   | 850     | x86_64       |
    | m1-xlarge | 8192   | 8   | 1690    | x86_64       |
    And I am on the hardware profiles page
    When another user deletes hardware profile "m1-small"
    And I follow "m1-small"
    Then I should be on the hardware profiles page
    And I should see "The record you tried to access does not exist, it may have been deleted"
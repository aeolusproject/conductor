Feature: Pool Families
  In order to manage my cloud infrastructure
  As a user
  I want to manage pool families

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List pool families
    Given I am on the homepage
    And there are these pool families:
    | name      |
    | pool_family1 |
    | pool_family2 |
    | pool_family3 |
    When I go to the admin pool families page
    Then I should see the following:
    | pool_family1 |
    | pool_family2 |
    | pool_family3 |

  Scenario: Show pool family details
    Given there is a pool family named "testpoolfamily"
    And I am on the admin pool families page
    When I follow "testpoolfamily"
    Then I should see "Name"

  Scenario: Create a new Pool family
    Given I am on the admin pool families page
    And there is not a pool family named "testpoolfamily"
    When I follow "Create"
    Then I should be on the new admin pool family page
    When I fill in "pool_family[name]" with "testpoolfamily"
    And I press "Save"
    Then I should be on the admin pool families page
    And I should see "Pool family was added."
    And I should have a pool family named "testpoolfamily"

  Scenario: Delete a pool family
    Given I am on the homepage
    And there is a pool family named "poolfamily1"
    When I go to the admin pool families page
    And I check "poolfamily1" pool family
    And I press "Delete"
    Then there should not exist a pool family named "poolfamily1"

  Scenario: Disallow deletion of default pool family
    Given I am on the admin pool families page
    Then I should see "default"
    When I check "default" pool family
    And I press "Delete"
    Then I should see "Could not delete the following Pool Families: default."
    And I should see "default"

  Scenario: Search for pool families
    Given there are these pool families:
    | name      |
    | first_family |
    | second_family |
    | third_family |
    Given I am on the admin pool families page
    Then I should see "first_family"
    And I should see "second_family"
    And I should see "third_family"
    When I fill in "q" with "second"
    And I press "Search"
    Then I should see "second_family"
    And I should not see "first_family"
    And I should not see "third_family"
    When I fill in "q" with "nomatch"
    And I press "Search"
    Then I should not see "first_family"
    And I should not see "second_family"
    And I should not see "third_family"
    When I fill in "q" with ""
    And I press "Search"
    Then I should see "first_family"
    And I should see "second_family"
    And I should see "third_family"

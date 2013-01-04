Feature: Pool Families
  In order to manage my cloud infrastructure
  As a user
  I want to manage pool families

  Background: Privileged User
    And I am an authorised user
    And I am logged in

  Scenario: List pool families
    Given I am on the homepage
    And there are these pool families:
    | name      |
    | pool_family1 |
    | pool_family2 |
    | pool_family3 |
    When I go to the pool families page
    Then I should see the following:
    | pool_family1 |
    | pool_family2 |
    | pool_family3 |

  Scenario: Show pool family details
    Given there is a pool family named "testpoolfamily"
    #with a pool named "bob"
    And I am on the pool families page
    When I follow "testpoolfamily"
    Then I should be on the page for the pool family "testpoolfamily"
    And I should see "testpoolfamily"

  Scenario: Create a new Pool family
    Given I am on the pool families page
    And there is not a pool family named "testpoolfamily"
    When I follow "new_pool_family_button"
    Then I should be on the new pool family page
    When I fill in "pool_family[name]" with "testpoolfamily"
    When I fill in "pool_family[quota_attributes][maximum_running_instances]" with "2"
    And I press "pool_family_submit"
    Then I should be on the pool families page
    And I should see a confirmation message
    And I should have a pool family named "testpoolfamily"

  Scenario: Delete a pool family
    Given I am on the homepage
    And there is a pool family named "poolfamily1"
    #with a pool named "carl"
    When I go to the pool families page
    And I follow "poolfamily1"
    And I press "delete_pool_family_button"
    Then there should not exist a pool family named "poolfamily1"

  Scenario: Disallow deletion of default pool family
    Given I am on the pool families page
    And there are no images in "default" pool family
    Then I should see "default"
    When I follow "default"
    And I press "delete_pool_family_button"
    Then I should see an error message
    And I should see "default"

  Scenario: Add provider account to pool family
    Given there is a pool family named "testpoolfamily"
    And there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And I am on the pool family provider accounts page
    Then I should see "Account Name"
    When I follow "Add Account"
    And I check the "testaccount" account
    And I press "Add Account"
    Then there should be 1 provider accounts assigned to "testpoolfamily"
    And I should see "testaccount"

  Scenario: Remove provider account from pool family
    Given there is a pool family named "testpoolfamily"
    And there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And there is a provider account "testaccount" related to pool family "testpoolfamily"
    And I am on the pool family provider accounts page
    Then I should see "testaccount"
    When I check the "testaccount" account
    And I press "remove_button"
    Then there should not exist a provider account assigned to "testpoolfamily"

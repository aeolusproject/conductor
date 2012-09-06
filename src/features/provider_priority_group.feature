Feature: Manage Provider Priority Groups

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List a Provider Priority Group
    Given a pool "testpool" exists
    And there is a provider priority group named "testproviderprioritygroup" for pool "testpool"
    When I am on the testpool's provider priority groups page
    Then I should see "testpool"

  Scenario: Create a new Provider Priority Group
    Given a pool "testpool" exists
    And there is a provider named "mockprovider"
    And there is a provider account named "testprovideraccount"
    And I am on the testpool's provider priority groups page
    When I follow "Add new"
    And I fill in "provider_priority_group_name" with "testproviderprioritygroup"
    And I fill in "provider_priority_group_score" with "50"
    And I check "provider_account_ids_"
    And I press "provider_priority_group_submit"
    Then I should see "Priority Group successfully created"

  Scenario: Tries to create a new Provider Priority Group with invalid input data
    Given a pool "testpool" exists
    And there is a provider named "mockprovider"
    And there is a provider account named "testprovideraccount"
    And I am on the testpool's provider priority groups page
    When I follow "Add new"
    And I press "provider_priority_group_submit"
    Then I should not see "Priority Group successfully created"
    And I should see "Score is not a number"

  Scenario: Delete a Provider Priority Group
    Given a pool "testpool" exists
    And there is a provider priority group named "testproviderprioritygroup" for pool "testpool"
    And I am on the testpool's provider priority groups page
    When I follow "Delete"
    Then I should see "Priority Group successfully deleted"

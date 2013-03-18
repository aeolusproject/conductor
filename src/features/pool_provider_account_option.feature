Feature: Manage Provider Pool Provider Account Options

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: List Provider Account scores
    Given a pool "testpool" exists
    When I am on the testpool's provider account options page
    Then I should see score "0" for provider account with label "test label1"

  Scenario: Create new Provider Account score
    Given a pool "testpool" exists
    When I am on the testpool's provider account options page
    And I follow "0"
    And I fill in "Score" with "50"
    And I press "Create Pool Provider Account Option"
    Then I should see "Provider Account Weight successfully modified."

  Scenario: Create new Provider Account score with invalid data
    Given a pool "testpool" exists
    When I am on the testpool's provider account options page
    And I follow "0"
    And I fill in "Score" with "500"
    And I press "Create Pool Provider Account Option"
    Then I should see "Some errors prevented the Pool Provider Account Option from being saved"

  Scenario: Edit Provider Account score
    Given a pool "testpool" with provider account "testprovideraccount" exists
    And a provider account score exists for pool "testpool" and provider account "testprovideraccount"
    When I am on the testpool's provider account options page
    And I follow "42"
    And I fill in "Score" with "24"
    And I press "Update Pool Provider Account Option"
    Then I should see "Provider Account Weight successfully modified."
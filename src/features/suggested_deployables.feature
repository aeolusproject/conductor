Feature: Manage Suggested Deployables
  In order to manage suggested deployables
  As an admin
  I want to add/edit/remove suggested deployables

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Create new deployable
    Given I am on the suggested deployables page
    When I follow "new_deployable_button"
    Then I should see "Add New Deployable"
    When I fill in "suggested_deployable[name]" with "test1"
    When I fill in "suggested_deployable[description]" with "description"
    When I fill in "suggested_deployable[url]" with "http://random_url"
    And I press "save_button"
    Then I should see "Deployable added"

  Scenario: Change the name
    Given a suggested deployable "testdepl" exists
    And I am on the suggested deployables page
    When I follow "testdepl"
    And I follow "edit_button"
    Then I should see "Editing Deployable"
    When I fill in "suggested_deployable[name]" with "testdepl-renamed"
    And I press "save_button"
    Then I should see "Deployable updated successfully!"
    And I should see "testdepl-renamed"

  Scenario: Show deployable details
    Given a suggested deployable "testdepl" exists
    And I am on the suggested deployables page
    When I follow "testdepl"
    Then I should see "testdepl"
    And I should see "Name"
    And I should see "description"
    And I should see "url"

  Scenario: Delete deployables
    Given a suggested deployable "testdepl1" exists
    And a suggested deployable "testdepl2" exists
    And I am on the suggested deployables page
    When I check "testdepl1" suggested deployable
    And I check "testdepl2" suggested deployable
    And I press "delete_button"
    Then there should be only 0 suggested deployables
    And I should be on the suggested deployables page
    And I should not see "testdepl1"
    And I should not see "testdepl2"

  Scenario: Delete deployable
    Given a suggested deployable "testdepl1" exists
    And I am on the suggested deployables page
    When I follow "testdepl1"
    And I press "delete_button"
    Then there should be only 0 suggested deployables
    And I should be on the suggested deployables page
    And I should not see "testdepl1"

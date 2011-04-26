Feature: Manage Deployables as a non-admin
  In order to manage my cloud infrastructure
  As an unprivileged user
  I want to manage deployables that I have permission to use

  Background:
    Given I am a new user

  Scenario: List deployables as a new user
    Given I am on the homepage
    And there is a deployable named "MySQL cluster"
    When I go to the image factory deployables page
    Then I should see "MySQL cluster"

  Scenario: View an existing deployable as a new user
    Given there is a deployable named "MySQL cluster"
    And I am on the image factory deployables page
    When I follow "MySQL cluster"
    Then I should see "Edit"

  @allow-rescue
  Scenario: Try to edit an existing deployable as a new user
    Given there is a deployable named "Apache Webserver"
    And I am on the image factory deployables page
    When I follow "Apache Webserver"
    And I follow "Edit"
    Then I should see "You have insufficient privileges to perform action."

  Scenario: Edit a deployable I created
    Given I am on the image factory deployables page
    When I follow "Create"
    Then I should be on the new image factory deployable page
    And I should see "New Deployable"
    When I fill in "deployable[name]" with "Mahout Server"
    And I press "Save"
    Then I should be on App's image factory deployable page
    And I should see "Deployable added"
    And I should have a deployable named "Mahout Server"
    And I should see "Mahout Server"
    When I follow "Mahout Server"
    And I follow "Edit"
    Then I should be on the edit image factory deployable page
    And I should see "Editing Deployable"
    When I fill in "deployable[name]" with "MahoutModified"
    And I press "Save"
    Then I should be on MahoutModified's image factory deployable page
    And I should see "Deployable updated"
    And I should have a deployable named "MahoutModified"
    And I should see "MahoutModified"

  Scenario: Create a deployable as a new user
    And I am on the image factory deployables page
    When I follow "Create"
    Then I should be on the new image factory deployable page
    And I should see "New Deployable"
    When I fill in "deployable[name]" with "Solr Server"
    And I press "Save"
    Then I should be on App's image factory deployable page
    And I should see "Deployable added"
    And I should have a deployable named "Solr Server"
    And I should see "Solr Server"

  @allow-rescue
  Scenario: Try to remove an existing assembly as a new user
    Given there is a deployable named "Mailserver Cluster"
    Given there is an assembly named "Postfix Node" belonging to "Mailserver Cluster"
    And I am on the image factory deployables page
    Then I should see "Mailserver Cluster"
    When I follow "Mailserver Cluster"
    And I follow "details_Assemblies"
    Then I should see "Postfix Node"
    When I check the "Postfix Node" assembly
    And I press "Remove Selected"
    Then I should see "You have insufficient privileges to perform action."

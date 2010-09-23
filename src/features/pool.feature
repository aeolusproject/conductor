Feature: Manage Pools
  In order to manage my cloud infrastructure
  As a user
  I want to manage my pools

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Create a new Pool
	Given I am on the instances page
	And there is not a pool named "mockpool"
	When I follow "Add a pool"
	Then I should be on the new pool page
	And I should see "Create a new Pool"
	When I fill in "pool_name" with "mockpool"
	And I press "Save"
	Then I should be on the show pool page
	And I should see "Pool added"
	And I should see "mockpool"
	And I should have a pool named "mockpool"

  Scenario: View Pool's Hardware Profiles
	  Given I have Pool Creator permissions on a pool named "mockpool"
	  And the Pool has the following Hardware Profiles:
	  | name      | memory | cpu |storage  | architecture |
	  | m1-small  | 1740   | 2   | 160.0   | i386         |
	  | m1-large  | 4096   | 4   | 850.0   | x86_64       |
	  | m1-xlarge | 8192   | 8   | 1690.0  | x86_64       |
	  And I am on the instances page
	  When I follow "mockpool"
	  Then I should be on the show pool page
	  When I follow "Hardware Profiles"
	  Then I should see the following:
	  | m1-small  | 1740 | 2 | 160.0  | i386   |
	  | m1-large  | 4096 | 4 | 850.0  | x86_64 |
	  | m1-xlarge | 8192 | 8 | 1690.0 | x86_64 |

  Scenario: View Pool's Realms
	  Given I have Pool Creator permissions on a pool named "mockpool"
	  And the Pool has the following Realms named "Europe, United States"
	  And I am on the instances page
	  When I follow "mockpool"
	  Then I should be on the show pool page
	  When I follow "Realms"
	  Then I should see "Europe"
	  And I should see "United States"

  @tag
  Scenario: View Pool's Quota Usage
    Given I have Pool Creator permissions on a pool named "mockpool"
    And the Pool has a quota with following capacities:
    | resource                  | capacity |
    | maximum_running_instances | 10       |
    | maximum_total_instances   | 15       |
    | running_instances         | 8        |
    | total_instances           | 15       |
    And I am on the instances page
    When I follow "mockpool"
    Then I should be on the show pool page
    When I follow "Quota"
    Then I should see the following:
    | Running Instances | 10           | 8             |
    | Total Instances   | 15           | 15            |
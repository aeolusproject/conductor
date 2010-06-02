Feature: Manage Pools
  In order to manage my cloud infrastructure
  As a user
  I want to manage my pools

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Create a new Pool
	Given I am on the homepage
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
	  Given I own a pool named "mockpool"
	  And the Pool has the following Hardware Profiles:
	  | name      | memory | storage | architecture |
	  | m1-small  | 1.7    | 160.0   | i386         |
	  | m1-large  | 7.5    | 850.0   | x86_64       |
	  | m1-xlarge | 15.0   | 1690.0  | x86_64       |
	  And I am on the homepage
	  When I follow "mockpool"
	  Then I should be on the show pool page
	  When I follow "Hardware Profiles"
	  Then I should see the following:
	  | m1-small  | 1.7  | 160.0   | i386   |
	  | m1-large  | 7.5  | 850.0   | x86_64 |
	  | m1-xlarge | 15.0 | 1690.0  | x86_64 |

  Scenario: View Pool's Realms
	  Given I own a pool named "mockpool"
	  And the Pool has the following Realms named "Europe, United States"
	  And I am on the homepage
	  When I follow "mockpool"
	  Then I should be on the show pool page
	  When I follow "Realms"
	  Then I should see "Europe"
	  And I should see "United States"

  @tag
  Scenario: View Pool's Quota Usage
    Given I own a pool named "mockpool"
    And the Pool has a quota with following capacities:
    | resource                  | capacity |
    | maximum_running_instances | 10       |
    | maximum_running_memory    | 10240    |
    | maximum_running_cpus      | 20       |
    | maximum_total_instances   | 15       |
    | maximum_total_storage     | 8500     |
    | running_instances         | 8        |
    | running_memory            | 9240     |
    | running_cpus              | 16       |
    | total_instances           | 15       |
    | total_storage             | 8400     |
    And I am on the homepage
    When I follow "mockpool"
    Then I should be on the show pool page
    When I follow "Quota"
    Then I should see the following:
    | Resource          | Max Capacity | Used Capacity | Free Capacity | % Used |
    | Running Instances | 10           | 8             | 2             | 80.00  |
    | Running Memory    | 10240        | 9240          | 1000          | 90.23  |
    | Running CPUs      | 20           | 16            | 4             | 80.00  |
    | Total Instances   | 15           | 15            | 0             | 100.00 |
    | Total Storage     | 8500         | 8400          | 100           | 98.82  |
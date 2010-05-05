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

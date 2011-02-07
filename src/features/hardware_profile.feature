Feature: Manage Pools
  In order to manage my cloud infrastructure
  As an admin
  I want to manage Hardware Profiles

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: View front end hardware profiles
    Given there are the following aggregator hardware profiles:
    | name      | memory | cpu |storage  | architecture |
    | m1-small  | 1740   | 2   | 160     | i386         |
    | m1-large  | 4096   | 4   | 850     | x86_64       |
    | m1-xlarge | 8192   | 8   | 1690    | x86_64       |
    And I am on the the hardware profiles page
    Then I should see the following:
    | Hardware Profile Name | Memory | Virtual CPU | Storage   | Architecture |
    | m1-small              | 1740   | 2           | 160       | i386         |
    | m1-large              | 4096   | 4           | 850       | x86_64       |
    | m1-xlarge             | 8192   | 8           | 1690      | x86_64       |

  Scenario: View a Hardware Profiles Properties
    Given there are the following aggregator hardware profiles:
    | name      | memory | cpu |storage  | architecture |
    | m1-small  | 1740   | 2   | 160     | i386         |
    | m1-large  | 4096   | 4   | 850     | x86_64       |
    | m1-xlarge | 8192   | 8   | 1690    | x86_64       |
    And I am on the the hardware profiles page
    When I follow "m1-small"
    Then I should see the following:
    | Name         | Kind  | Range First | Range Last | Enum Entries | Default Value | Unit  |
    | memory       | fixed | n/a         | n/a        | n/a          | 1740          | MB    |
    | cpu          | fixed | n/a         | n/a        | n/a          | 2             | count |
    | storage      | fixed | n/a         | n/a        | n/a          | 160           | GB    |
    | architecture | fixed | n/a         | n/a        | n/a          | i386          | label |

  Scenario: View a Front End Hardware Profiles Matching Provider Hardware Profiles
    Given there are the following aggregator hardware profiles:
    | name      | memory | cpu |storage  | architecture |
    | m1-small  | 1740   | 2   | 160     | i386         |
    And the Hardare Profile "m1-small" has the following Provider Hardware Profiles:
    | name      | memory | cpu |storage  | architecture |
    | m1-small  | 1740   | 2   | 160     | i386         |
    And I am on the hardware profiles page
    When I follow "m1-small"
    And I follow "Matching Provider Hardware Profiles"
    Then I should see the following:
    | Name      | Memory | CPU | Storage  | Architecture |
    | m1-small  | 1740   | 2   | 160      | i386         |

  Scenario: Search for hardware profiles
    Given there are the following aggregator hardware profiles:
    | name      | memory | cpu |storage  | architecture |
    | m1-small  | 1740   | 2   | 160     | i386         |
    | m1-large  | 4096   | 4   | 850     | x86_64       |
    | m1-xlarge | 8192   | 8   | 1690    | x86_64       |
    And I am on the the hardware profiles page
    When I fill in "q" with "large"
    And I press "Search"
    Then I should see "m1-large"
    And I should see "m1-xlarge"
    And I should not see "m1-small"
    When I fill in "q" with "small"
    And I press "Search"
    Then I should see "m1-small"
    And I should not see "m1-large"
    And I should not see "m1-xlarge"
    When I fill in "q" with ""
    And I press "Search"
    Then I should see "m1-small"
    And I should see "m1-large"
    And I should see "m1-xlarge"
    When I fill in "q" with "i386"
    And I press "Search"
    Then I should see "m1-small"
    And I should not see "m1-large"
    And I should not see "m1-xlarge"

  Scenario: Frontend HWP with correct id is displayed when id is greater than 10
    Given there are 10 hardware profiles
    And there is a "mock1" hardware profile
    And I am on the the hardware profiles page
    When I follow "mock1"
    Then I should see "mock1(Front End)"

#  Scenario: Create a new Hardware Profile
#    Given I am an authorised user
#   And I am on the hardware profiles page
#    When I follow "New Hardware Profile"
#    Then I should be on the new hardware profile page
#    When I fill in "name" with "Test Hardware Profile"
#    And I enter the following details for the Hardware Profile Properties
#    | name         | kind  | range_first | range_last | property_enum_entries | value         | unit  |
#    | memory       | fixed |             |            |                       | 1740          | MB    |
#    | cpu          | range | 1           | 4          |                       | 2             | count |
#    | storage      | enum  |             |            | 250, 300, 350         | 300           | GB    |
#    | architecture | fixed |             |            |                       | i386          | label |
#    And I press "Save"
#    Then I should be on the hardware profiles page
#    And I should see the following:
#    | Test Hardware Profile | 1740   | 1 - 4 | 250, 300, 350 | i386 |

#  Scenario: Check New Hardware Profile matching Provider Hardware Profiles
#    Given I am an authorised user
#    And there are the following provider hardware profiles:
#    | name         | memory | cpu |storage  | architecture |
#    | m1-small     | 1740   | 1   | 250     | i386         |
#    | m1-medium    | 1740   | 2   | 500     | i386         |
#    | m1-large     | 2048   | 4   | 850     | x86_64       |
#    And I am on the new hardware profile page
#    When I fill in "name" with "Test Hardware Profile"
#    And I enter the following details for the Hardware Profile Properties
#    | name         | kind  | range_first | range_last | property_enum_entries | value         | unit  |
#    | memory       | fixed |             |            |                       | 1740          | MB    |
#    | cpu          | range | 1           | 4          |                       | 2             | count |
#    | storage      | range | 250         | 500        |                       | 300           | GB    |
#    | architecture | fixed |             |            |                       | i386          | label |
#    And I press "Check Matches"
#    Then I should see the following:
#    | Name         | Memory | CPU | Storage | Architecture |
#    | m1-small     | 1740   | 1   | 250     | i386         |
#    | m1-medium    | 1740   | 2   | 500     | i386         |

#  Scenario: Update a HardwareProfile
#    Given I am an authorised user
#    And there are the following aggregator hardware profiles:
#    | name     | memory | cpu |storage  | architecture |
#    | m1-small | 1740   | 2   | 160     | i386         |
#    And I am on the hardware profiles page
#    When I follow "m1-small"
#    Then I should see "Properties"
#    When I follow "edit"
#    Then I should be on the edit hardware profiles page
#    When I enter the following details for the Hardware Profile Properties
#    | name         | kind  | range_first | range_last | property_enum_entries | value         |
#    | memory       | fixed |             |            |                       | 1740          |
#    | cpu          | range | 1           | 4          |                       | 1             |
#    | storage      | range | 250         | 500        |                       | 300           |
#    | architecture | fixed |             |            |                       | i386          |
#    And I press "Save"
#    Then I should be on the hardware profiles page
#    Then I should see the following:
#    | Name         | Memory | CPU       | Storage   | Architecture |
#    | m1-small     | 1740   | 1 - 4     | 250 - 500 | i386         |

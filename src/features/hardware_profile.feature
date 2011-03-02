Feature: Manage Pools
  In order to manage my cloud infrastructure
  As an admin
  I want to manage Hardware Profiles

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: View front end hardware profiles
    Given there are the following conductor hardware profiles:
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

  Scenario: View a Front End Hardware Profiles Properties
    Given there are the following conductor hardware profiles:
    | name      | memory | cpu |storage  | architecture |
    | m1-small  | 1740   | 2   | 160     | i386         |
    | m1-large  | 4096   | 4   | 850     | x86_64       |
    | m1-xlarge | 8192   | 8   | 1690    | x86_64       |
    And I am on the the hardware profiles page
    When I follow "m1-small"
    Then I should see the following:
    | Name         | Minimum Value | Unit  |
    | memory       | 1740          | MB    |
    | cpu          | 2             | count |
    | storage      | 160           | GB    |
    | architecture | i386          | label |

  Scenario: View a Front End Hardware Profiles Matching Provider Hardware Profiles
    Given there are the following conductor hardware profiles:
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
    Given there are the following conductor hardware profiles:
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

   Scenario: Create a new Hardware Profile
     Given I am an authorised user
    And I am on the hardware profiles page
     When I follow "New Hardware Profile"
     Then I should be on the new hardware profile page
     When I fill in "name" with "Test Hardware Profile"
     And I enter the following details for the Hardware Profile Properties
     | name         | value | unit  |
     | memory       | 1740  | MB    |
     | cpu          | 2     | count |
     | storage      | 250   | GB    |
     | architecture | i386  | label |
     And I press "Save"
     Then I should be on the hardware profiles page
     And I should see the following:
     | Test Hardware Profile | 1740   | 2 | 250 | i386 |

  Scenario: Check New Hardware Profile matching Provider Hardware Profiles
    Given I am an authorised user
    And there is a provider named "provider1"
    And there is a provider named "provider2"
    And "provider1" has the following hardware profiles:
    | name         | memory | cpu |storage  | architecture |
    | m1-small     | 1740   | 1   | 250     | i386         |
    | m1-medium    | 1740   | 2   | 500     | i386         |
    | m1-large     | 2048   | 4   | 850     | x86_64       |
    And "provider2" has the following hardware profiles:
    | name         | memory | cpu |storage  | architecture |
    | m1-small     | 4048   | 4   | 500     | i386         |
    | m1-medium    | 8192   | 4   | 500     | i386         |
    | m1-large     | 2048   | 4   | 850     | x86_64       |
    And I am on the new hardware profile page
    When I fill in "name" with "Test Hardware Profile"
    And I enter the following details for the Hardware Profile Properties
    | name         | value         | unit  |
    | memory       | 1740          | MB    |
    | cpu          | 2             | count |
    | storage      | 300           | GB    |
    | architecture | i386          | label |
    And I press "Check Matches"
    Then I should see the following:
    | Provider  | Name         | Memory | CPU | Storage | Architecture |
    | provider1 | m1-medium    | 1740   | 2   | 500     | i386         |
    | provider2 | m1-small     | 4048   | 4   | 500     | i386         |

   Scenario: Update a HardwareProfile
     Given I am an authorised user
     And there are the following conductor hardware profiles:
     | name     | memory | cpu |storage  | architecture |
     | m1-small | 2048   | 4   | 160     | x86_64         |
     And I am on the hardware profiles page
     When I follow "m1-small"
     Then I should see "Properties"
     When I follow "edit"
     Then I should be on the edit hardware profiles page
     When I enter the following details for the Hardware Profile Properties
     | name         | value | unit  |
     | memory       | 1740  | MB    |
     | cpu          | 2     | count |
     | storage      | 250   | GB    |
     | architecture | i386  | label |
     And I press "Save"
     Then I should be on the hardware profiles page
     Then I should see the following:
     | Name         | Memory | CPU | Storage | Architecture |
     | m1-small     | 1740   | 2   | 250     | i386         |

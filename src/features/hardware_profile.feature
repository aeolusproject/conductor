Feature: Manage Pools
  In order to manage my cloud infrastructure
  As an admin
  I want to manage Hardware Profiles

  Background:
    Given I am an authorised user
    And I am logged in
    And I am using new UI

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
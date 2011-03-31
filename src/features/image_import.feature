Feature: Import Images
  In order to use other images in my cloud infrastructure
  As a user
  I want to import images from other providers

  Background:
    Given I am an authorised user
    And I am logged in
    And I am on the homepage
    And there is a provider named "testprovider"
    And there is a provider account named "provider1"
    And There is a mock pulp repository
    When I go to the new image factory image import page
    Then I should be on the new image factory image import page
    When I select "provider1" from "provider_account_id"
    And I fill in "ami_id" with "img1"

  Scenario: Import a new image
    Given I press "Import"
    Then I should see "Image successfully imported"
    And I should be on the image factory templates page

  Scenario: Import an already imported image
    Given I press "Import"
    When I go to the new image factory image import page
    When I select "provider1" from "provider_account_id"
    And I fill in "ami_id" with "img1"
    And I press "Import"
    Then I should see "Image 'img1' is already imported"
    And I should be on the image factory image imports page

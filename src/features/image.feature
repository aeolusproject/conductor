Feature: Manage Images
  In order to manage my cloud infrastructure
  As a user
  I want to manage instances

  Background:
    Given I am an authorised user
    And I am logged in

  Scenario: Uploading a template without specifying the file
    Given there is a pool family named "testpoolfamily"
    And I am on the new image page for "testpoolfamily"
    When I fill in "base_image_name" with "my template"
    And I press "file_button"
    Then I should see an error message

  Scenario: Edit an invalid XML when creating an image
    Given there is a pool family named "testpoolfamily"
    And I am on the pool families page
    And I am on the new image page for "testpoolfamily"
    When I fill in "base_image_name" with "my template"
    And I attach the file "features/upload_files/template.xml" to "template_file"
    And I check "edit"
    And I press "file_button"
    Then I should be on the edit xml images page
    When I fill in "base_image_template_attributes_xml" with an invalid XML
    And I press "save_image"
    Then I should see an error message

  Scenario: Show image details
    Given there is an image "testimage"
    And I am on the images page
    When I follow link with text "testimage"
    Then I should be on the testimage's show image page
    And I should see "testimage"

  Scenario: Build an image
    Given there is an image "testimage"
    And there is a provider named "mockprovider"
    And there is a provider account named "testaccount"
    And I am on the testimage's show image page
    And an image build request will succeed
    When I press "Build"
    Then I should be on the testimage's show image page
    And I should see "Building"

  #Scenario: Delete an image
  #Scenario: Delete a provider image
  #Scenario: Push a provider image

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
    When I fill in "name" with "my template"
    And I press "file_button"
    Then I should see "You must specify the template XML file"

  Scenario: Edit an invalid XML when creating an image
    Given there is a pool family named "testpoolfamily"
    And I am on the pool families page
    And I am on the new image page for "testpoolfamily"
    When I fill in "name" with "my template"
    And I attach the file "features/upload_files/template.xml" to "image_file"
    And I check "edit"
    And I press "file_button"
    Then I should be on the edit xml images page
    When I fill in "image_xml" with an invalid XML
    And I press "save_image"
    Then I should see "Failed to parse XML."

#
# FIXME - This test is failing, but fixing it requires fixing a larger bug: we don't
# use VCR the way we think we do when interacting with iwhd... That's a large can of worms.
#
#  Scenario: Show image details
#    Given there is an image
#    And I am on the images page
#    When I click on the image
#    Then I should be on the image's show page
#    And I should see the image's name

  # TODO: no simple way how to mockup this now
  #Scenario: Delete an image
  #Scenario: Delete a provider image
  #Scenario: Push a provider image

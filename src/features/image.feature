#
# FIXME - This test is failing, but fixing it requires fixing a larger bug: we don't
# use VCR the way we think we do when interacting with iwhd... That's a large can of worms.
#

#Feature: Manage Images
#  In order to manage my cloud infrastructure
#  As a user
#  I want to manage instances

#  Background:
#    Given I am an authorised user
#    And I am logged in


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

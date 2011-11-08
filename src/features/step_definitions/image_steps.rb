Given /^there is an image$/ do
  @image = Aeolus::Image::Warehouse::Image.first
end

When /^I click on the image$/ do
  click_link(@image.name)
end

Then /^I should see the image's name$/ do
  if page.respond_to? :should
    page.should have_content(@image.name)
  else
    assert page.has_content?(@image.name)
  end
end

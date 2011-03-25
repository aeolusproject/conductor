When /^another user deletes hardware profile "([^"]*)"$/ do |name|
  hwp = HardwareProfile.find_by_name(name)
  hwp.delete
end
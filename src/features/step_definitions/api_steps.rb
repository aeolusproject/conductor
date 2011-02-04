Then /^I should see xml element "([^"]*)"$/ do |element|
  Then %{I should see "#{element}"}
end

Then /^I should see xml element "([^"]*)" with the following properties:$/ do |element, properties|
  Then %{I should see xml element "#{element}"}
  Then %{I should see the following: "#{properties}"}
end

When /^a client requests matching hardware profiles for "([^"]*)"$/ do |name|
  uri = url_for :action => 'matching_profiles', :controller => 'admin/hardware_profiles', :id => HardwareProfile.find_by_name(name)
  send_xml_get(uri)
end

Then /^the root element should be "([^"]*)"$/ do |element|
  @last_element = @xml_response.xpath('/'+element).first
  @last_element.should_not be_nil
  @last_element.name.should == element
end

Then /^there should exist the following xpath: "([^"]*)"$/ do |xpath|
  @path = xpath
  @last_element = @xml_response.xpath(xpath).first
  @last_element.should_not be_nil
end

Then /^this path should have the value "([^"]*)"$/ do |value|
  @last_element.content.should == value
end

Given /^user "([^"]*)" owns instance "([^"]*)"$/ do |user, instance|
  user = User.find_by_login(user)
  instance = Instance.find_by_name(instance)
  instance.owner = user
  instance.save!
end

When /^a client requests "([^"]*)" for instance "([^"]*)" for cloud account "([^"]*)"$/ do |action, instance, cloud_account|
  instance = Instance.find_by_name(instance)
  cloud_account = CloudAccount.find_by_label(cloud_account)
  uri = url_for :action => action, :controller => 'resources/instances', :instance_id => instance.id, :cloud_account_id => cloud_account.id
  send_xml_get(uri)
end

Then /^this path should contain the following elements:$/ do |table|
  table.hashes.each do |hash|
    @last_element.name.should == hash['element']
    attr = @last_element.attributes
    attr['kind'].value.should == hash['kind']
    attr['name'].value.should == hash['name']
    attr['unit'].value.should == hash['unit']
    attr['value'].value.should == hash['value']
    #TODO: Fix this, NOKOGIRI is outputting text elements containing only \n, between property elements.
    begin
      @last_element = @last_element.next.next
    rescue Exception => e
    end
  end
end

def send_xml_get(uri)
  header 'Accept', 'application/xml'
  get uri
  @xml_response = Nokogiri::XML(response.body)
end

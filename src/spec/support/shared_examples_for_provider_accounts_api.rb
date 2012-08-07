
shared_examples_for "having XML with provider accounts" do
  # TODO: implement more attributes checks
  subject { Nokogiri::XML(response.body) }
  context "list of provider accounts" do
    let(:xml_provider_accounts) { subject.xpath('//provider_accounts/provider_account') }
    context "number of provider accounts" do
      it { xml_provider_accounts.size.should be_eql(number_of_provider_accounts) }
    end
    it "should have correct provider accounts" do
      provider_accounts.each do |provider_account|
        xml_provider_account = xml_provider_accounts.xpath("//provider_account[@id=\"#{provider_account.id}\"]")
        xml_provider_account.xpath('name').text.should be_eql(provider_account.name.to_s)
        xml_provider_account.xpath('@href').text.should be_eql(api_provider_account_url(provider_account))
      end
    end
    it "should have not incorrect provider accounts" do
      other_provider_accounts.each do |provider_account|
        xml_provider_account = xml_provider_accounts.xpath("//provider_account[@id=\"#{provider_account.id}\"]")
        xml_provider_account.should be_empty
      end
    end
  end
end

shared_examples_for "having correct set of credentials" do
  it "should be correct" do
    provider_account.credentials.each do |credential|
      label = credential.credential_definition.label
      value = credential.value
      xml_provider_account.xpath('//' + label).text.should be_eql(value)
    end
  end
end

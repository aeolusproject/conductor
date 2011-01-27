#Seed the DB with fixture data

# We can't stub out these methods properly in cucumber, and we don't want to
# couple these tests to require the core server be running (connections should be tested
# in the client code), so override the methods for tests here.
Provider.class_eval do
  def valid_framework?
    true
  end

  def populate_hardware_profiles
    [[:mock_hwp1, :agg_hwp1], [:mock_hwp2, :agg_hwp2]].each do |mp_name, ap_name|
      mock = Factory(mp_name, :provider_id => self.id)
      agg_mock = Factory(ap_name, :external_key => self.name + Realm::CONDUCTOR_REALM_ACCOUNT_DELIMITER + mock.name)
      agg_mock.provider_hardware_profiles << mock
    end
    return true
  end

end

ProviderAccount.class_eval do

  alias :generate_auth_key_original :generate_auth_key

  def validate_credentials
    true
  end

  def generate_auth_key
    key = OpenStruct.new(:pem => 'PEM')
    def key.id
      "mock_#{Time.now.to_i}_key_#{self.object_id}"
    end
    key
  end

#  def instance_key
#    @key = mock('Key', :null_object => true)
#    @key.stub!(:pem).and_return("PEM")
#    @key.stub!(:id).and_return("1_user")
#    @key
#  end
end

RepositoryManager.class_eval do
  def load_config
    [{
      'baseurl' => 'http://pulptest',
      'yumurl'  => 'http://pulptest',
      'type'    => 'pulp',
    }]
  end
end

Template.class_eval do
  def upload
    true
  end
end

#Seed the DB with fixture data
Fixtures.reset_cache
fixtures_folder = File.join(Rails.root, 'spec', 'fixtures')
fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
Fixtures.create_fixtures(fixtures_folder, fixtures)

# We can't stub out these methods properly in cucumber, and we don't want to
# couple these tests to require the core server be running (connections should be tested
# in the client code), so override the methods for tests here.
Provider.class_eval do
  def valid_framework?
    true
  end

  def set_cloud_type
    self.cloud_type = Factory(:mock_provider).cloud_type
  end

  def populate_hardware_profiles
    [[:mock_hwp1, :agg_hwp1], [:mock_hwp2, :agg_hwp2]].each do |mp_name, ap_name|
      mock = Factory(mp_name, :provider_id => self.id)
      agg_mock = Factory(ap_name, :external_key => self.name + Realm::AGGREGATOR_REALM_ACCOUNT_DELIMITER + mock.name)
      agg_mock.provider_hardware_profiles << mock
    end
    return true
  end

end

CloudAccount.class_eval do
  
  alias :generate_cloud_account_key_original :generate_cloud_account_key 

  def validate_credentials
    true
  end

  def generate_cloud_account_key
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

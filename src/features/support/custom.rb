#Seed the DB with fixture data

# We can't stub out these methods properly in cucumber, and we don't want to
# couple these tests to require the core server be running (connections should be tested
# in the client code), so override the methods for tests here.
Provider.class_eval do
  def valid_framework?
    true
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

InstanceKey.class_eval do
  def replace_on_server(addr, new)
    true
  end
end

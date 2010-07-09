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
end

CloudAccount.class_eval do
  def valid_credentials?
    true
  end
end
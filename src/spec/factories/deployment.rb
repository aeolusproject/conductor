FactoryGirl.define do
  factory :deployment do
    sequence(:name) { |n| "deployment#{n}" }
    association :pool, :factory => :pool
    association :owner, :factory => :user
    after_build do |deployment|
      deployment.deployable_xml = DeployableXML.import_xml_from_url("http://localhost/deployables/deployable1.xml")
    end
  end
end

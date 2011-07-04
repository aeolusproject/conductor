Factory.define :deployment do |d|
  d.sequence(:name) { |n| "deployment#{n}" }
  d.association :pool, :factory => :pool
  d.association :owner, :factory => :user
  d.after_build do |deployment|
    deployment.deployable_xml = DeployableXML.import_xml_from_url("http://localhost/deployables/deployable1.xml")
  end
end

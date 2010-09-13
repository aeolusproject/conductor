Factory.define :default_zone_metadata, :class => MetadataObject  do |o|
  o.key 'default_zone'
  o.value {Factory.create(:zone).id}
  o.object_type 'Zone'
end

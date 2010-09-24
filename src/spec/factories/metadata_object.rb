Factory.define :metadata_object do |o|
  o.key 'key'
  o.value 'value'
  o.object_type nil
end

Factory.define :default_zone_metadata, :parent => :metadata_object do |o|
   o.key 'default_zone'
   o.value {Factory.create(:zone).id}
   o.object_type 'Zone'
end
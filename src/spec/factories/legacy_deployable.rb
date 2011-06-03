Factory.define :legacy_deployable do |a|
  a.sequence(:name) { |n| "deployable#{n}" }
  a.legacy_assemblies { |t| [t.association(:legacy_assembly)] }
  a.association :owner, :factory => :user
end

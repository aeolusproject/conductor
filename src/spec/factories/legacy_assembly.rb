Factory.define :legacy_assembly do |a|
  a.sequence(:name) { |n| "assembly#{n}" }
  a.architecture 'x86_64'
  a.association :owner, :factory => :user
  a.legacy_templates { |t| [t.association(:legacy_template)] }
end

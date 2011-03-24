Factory.define :credential_definition do |f|
  f.sequence(:name) { |n| "field#{n}" }
  f.sequence(:label) { |n| "field#{n}" }
  f.input_type 'text'
  f.association :provider_type
end

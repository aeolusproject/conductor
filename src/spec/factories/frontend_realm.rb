Factory.define :frontend_realm do |r|
  r.sequence(:name) { |n| "realm#{n}" }
end

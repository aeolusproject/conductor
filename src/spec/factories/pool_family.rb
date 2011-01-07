Factory.define :pool_family do |z|
  z.sequence(:name) { |n| "pool_family#{n}" }
  z.description 'default pool family'
end

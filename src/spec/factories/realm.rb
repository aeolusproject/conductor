Factory.define :realm do |r|
  r.sequence(:name) { |n| "realm#{n}" }
  r.sequence(:external_key) { |n| "key#{n}" }
  r.association(:provider)
end

Factory.define :realm1, :parent => :realm do |r|
end

Factory.define :realm2, :parent => :realm do |r|
end

Factory.define :realm3, :parent => :realm do |r|
end

Factory.define :realm4, :parent => :realm do |r|
end

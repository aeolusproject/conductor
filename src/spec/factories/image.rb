Factory.define :image do |i|
  i.sequence(:name) { |n| "image#{n}" }
  i.sequence(:external_key) { |n| "key#{n}" }
  i.architecture 'i686'
  i.provider {|p| Provider.new }
end

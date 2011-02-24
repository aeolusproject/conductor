Factory.define :icicle do |i|
  i.sequence(:uuid) { |n| "icicle#{n}" }
end

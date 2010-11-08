Factory.define :template do |i|
  i.sequence(:name) { |n| "template#{n}" }
  i.platform 'fedora'
end

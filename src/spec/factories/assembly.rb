Factory.define :assembly do |a|
  a.sequence(:name) { |n| "assembly#{n}" }
  a.architecture 'x86_64'
  a.templates { |t| [t.association(:template)] }
end

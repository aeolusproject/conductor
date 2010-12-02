Factory.define :role do |r|
  r.sequence(:name) {|n| "Role name #{n}" }
  r.scope 'Pool'
end

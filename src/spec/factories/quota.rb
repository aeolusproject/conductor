Factory.define :quota do |f|
  f.maximum_running_instances 10
  f.maximum_total_instances 15
end

Factory.define :full_quota, :parent => :quota do |f|
  f.running_instances 10
  f.total_instances 15
end
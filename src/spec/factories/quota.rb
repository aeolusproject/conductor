Factory.define :quota do |f|
  f.maximum_running_instances 10
  f.maximum_running_memory "10240"
  f.maximum_running_cpus 20
  f.maximum_total_instances 15
  f.maximum_total_storage "8500"
end

Factory.define :full_quota, :parent => :quota do |f|
  f.running_instances 10
  f.running_memory "10240"
  f.running_cpus 20
  f.total_instances 15
  f.total_storage "8500"
end
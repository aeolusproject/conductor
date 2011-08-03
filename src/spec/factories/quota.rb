FactoryGirl.define do

  factory :quota do
    maximum_running_instances 10
    maximum_total_instances 15
  end

  factory :full_quota, :parent => :quota do
    running_instances 10
    total_instances 15
  end

  factory :unlimited_quota, :parent => :quota do
    maximum_running_instances nil
    maximum_total_instances nil
  end

end

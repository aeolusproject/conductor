FactoryGirl.define do

  factory :pool do
    sequence(:name) { |n| "mypool#{n}" }
    pool_family { PoolFamily.find_by_name('default') }
    association :quota
    enabled true
  end

  factory :tpool, :parent => :pool do
    name 'tpool'
  end

  factory :disabled_pool, :parent => :pool do
    enabled false
  end

end

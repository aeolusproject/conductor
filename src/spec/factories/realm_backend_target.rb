FactoryGirl.define do
  factory :realm_backend_target do
    association :frontend_realm
    association :realm_or_provider, :fatcory => :backend_realm
  end
end

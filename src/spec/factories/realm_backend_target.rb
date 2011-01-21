Factory.define :realm_backend_target do |r|
  r.association(:frontend_realm)
  r.association :realm_or_provider, :fatcory => :backend_realm
end

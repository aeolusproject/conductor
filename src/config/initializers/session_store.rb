# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails23-app_session',
  :secret      => '41713a6b4a92b5b7af55314d2ef6fc499a177269ea91b9fdaa7d15c42e1234b70b32f52278ae26b774b38dbdfeb7d078585d10f643e81b6615d32410f192f1de'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store

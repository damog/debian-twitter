# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_microb_session',
  :secret      => '2078f584e90c249ce7f533e4c50819c7ef6bc3f97f2ff82bdfcb8b2ee17bb99079827acaba2b9eb6f128c1c34ababe2636ce9a23ef66021ced3811bcbfd59201'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

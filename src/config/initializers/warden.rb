Rails.configuration.middleware.use RailsWarden::Manager do |config|
  config.failure_app = UserSessionsController
  config.default_scope = :user

  # all UI requests are handled in the default scope
  config.scope_defaults(
    :user,
    #:strategies   => [AppConfig.warden.to_sym],
    :strategies   => [:database],
    :store        => true,
    :action       => 'unauthenticated'
  )
end

class Warden::SessionSerializer
  def serialize(user)
    raise ArgumentError, "Cannot serialize invalid user object: #{user}" if not user.is_a? User and user.id.is_a? Integer
    user.id
  end

  def deserialize(id)
    raise ArgumentError, "Cannot deserialize non-integer id: #{id}" unless id.is_a? Integer
    User.find(id) rescue nil
  end
end

# authenticate against database
Warden::Strategies.add(:database) do
  def valid?
    params[:login] && params[:password]
  end

  def authenticate!
    Rails.logger.debug("Warden is authenticating #{params[:login]} against database")
    u = User.authenticate(params[:login], params[:password])
    u ? success!(u) : fail!("Username or password is not correct - could not log in")
  end
end

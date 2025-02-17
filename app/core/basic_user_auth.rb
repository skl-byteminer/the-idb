class BasicUserAuth < Struct.new(:realm, :context)

  def authenticate(login, pass)
    validate(login, pass) do |user|
      context.current_user = user
    end
  end

  def validate(login, pass, &block)
    validate_ldap(login, pass, &block)
  end

  # currently disabled
  def validate_local(login, pass)
    user = User.find_by(login: login)
    return unless user
    
    if user.valid_password?(pass)
      yield(user) if block_given?
    end
    user
  end

  def validate_ldap(login, pass)
    ldap = LDAP::Connection.new(IDB.config.ldap)
    # this method is declared in app/core/ldap
    user = ldap.find_user(login, pass)

    if user
      is_admin = ldap.is_admin?(login)
      yield(UserService.update_from_virtual_user(user, pass, is_admin)) if block_given?
    end
    user
  end
end

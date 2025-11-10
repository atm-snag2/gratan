class Gratan::Driver
  class MySQL8 < Base
    # MySQL 8 specific implementation
    # MySQL 8 has different authentication and privilege management
    
    def show_create_user(user, host)
      query("SHOW CREATE USER #{quote_user(user, host)}").first.values.first
    end

    def version
      @version ||= begin
        result = query("SELECT VERSION()").first
        result.values.first
      end
    end

    # MySQL 8 removed PASSWORD() function, passwords must be set differently
    def set_password(user, host, password, options = {})
      password ||= ''

      if options[:hash]
        # If already hashed, use it directly in ALTER USER
        sql = "ALTER USER #{quote_user(user, host)} IDENTIFIED WITH mysql_native_password AS #{password}"
      elsif password.empty?
        # Empty password
        sql = "ALTER USER #{quote_user(user, host)} IDENTIFIED BY ''"
      else
        # Plain password - use ALTER USER
        sql = "ALTER USER #{quote_user(user, host)} IDENTIFIED BY '#{escape(password)}'"
      end

      update(sql)
    end

    # In MySQL 8, IDENTIFIED BY in GRANT is deprecated
    # We should use ALTER USER for authentication
    def identify(user, host, identifier)
      if identifier =~ /\APASSWORD\s+'(.+)'\z/
        # Hash format
        password_hash = $1
        set_password(user, host, password_hash, :hash => true)
      else
        # Plain text password
        set_password(user, host, identifier)
      end
    end
  end
end

class Gratan::Driver
  class MySQL5 < Base
    # MySQL 5 specific implementation
    # SHOW CREATE USER is not available in MySQL < 5.7
    def show_create_user(user, host)
      # In MySQL 5.6 and earlier, SHOW CREATE USER doesn't exist
      # Return nil to indicate this feature is not supported
      nil
    end

    def version
      @version ||= begin
        result = query("SELECT VERSION()").first
        result.values.first
      end
    end
  end
end

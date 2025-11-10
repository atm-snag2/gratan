class Gratan::Driver
  class MySQL57 < Base
    # MySQL 5.7 specific implementation
    # SHOW CREATE USER is available in MySQL 5.7+
    def show_create_user(user, host)
      query("SHOW CREATE USER #{quote_user(user, host)}").first.values.first
    end

    def version
      @version ||= begin
        result = query("SELECT VERSION()").first
        result.values.first
      end
    end
  end
end

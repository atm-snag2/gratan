describe 'Gratan::Client#apply' do
  before(:each) do
    apply {
      <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
      RUBY
    }
  end

  def expect_initial_state
    expect(show_create_users).to match_array [
      start_with("CREATE USER `bob`@`localhost` IDENTIFIED WITH 'mysql_native_password' REQUIRE NONE PASSWORD EXPIRE"),
      start_with("CREATE USER `scott`@`localhost` IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL PASSWORD EXPIRE"),
    ]
    expect(show_grants).to match_array [
      *grant_all_priv(user: 'bob', host: 'localhost', with: 'GRANT OPTION'),
      "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL",
    ].normalize
  end

  context 'when before subject' do
    it do
      expect_initial_state
    end
  end

  context 'when update password' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: '123', required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost', identified: '456' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_create_users).to match_array [
        start_with("CREATE USER `bob`@`localhost` IDENTIFIED WITH 'mysql_native_password' AS '*531E182E2F72080AB0740FE2F2D689DBE0146E04' REQUIRE NONE PASSWORD EXPIRE"),
        start_with("CREATE USER `scott`@`localhost` IDENTIFIED WITH 'mysql_native_password' AS '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257' REQUIRE SSL PASSWORD EXPIRE"),
      ]
      expect(show_grants).to match_array [
        *grant_all_priv(user: 'bob', host: 'localhost', auth: "IDENTIFIED BY PASSWORD '*531E182E2F72080AB0740FE2F2D689DBE0146E04'", with: 'GRANT OPTION'),
        "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*23AE809DDACAF96AF0FD78ED04B6A265E05AA257' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when remove password' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: nil, required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_create_users).to match_array [
        start_with("CREATE USER `bob`@`localhost` IDENTIFIED WITH 'mysql_native_password' REQUIRE NONE PASSWORD EXPIRE "),
        start_with("CREATE USER `scott`@`localhost` IDENTIFIED WITH 'mysql_native_password' REQUIRE SSL PASSWORD EXPIRE"),
      ]
      expect(show_grants).to match_array [
        *grant_all_priv(user: 'bob', host: 'localhost', with: 'GRANT OPTION'),
        "GRANT USAGE ON *.* TO 'scott'@'localhost' REQUIRE SSL",
      ].normalize
    end
  end

  context 'when skip update password' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect_initial_state
    end
  end

  context 'when update require' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', required: 'X509' do
  on '*.*' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost', required: 'SSL' do
  on '*.*', with: 'GRANT OPTION' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_create_users).to match_array [
        start_with("CREATE USER `bob`@`localhost` IDENTIFIED WITH 'mysql_native_password' REQUIRE SSL PASSWORD EXPIRE"),
        start_with("CREATE USER `scott`@`localhost` IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE X509 PASSWORD EXPIRE"),
      ]
      expect(show_grants).to match_array [
        *grant_all_priv(user: 'bob', host: 'localhost', required: 'SSL', with: 'GRANT OPTION'),
        "GRANT USAGE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE X509",
      ].normalize
    end
  end

  context 'when update with option' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger', required: 'SSL' do
  on '*.*', with: 'GRANT OPTION MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4' do
    grant 'USAGE'
  end
end

user 'bob', 'localhost' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end
end
        RUBY
      }

      expect(show_create_users).to match_array [
        start_with("CREATE USER `bob`@`localhost` IDENTIFIED WITH 'mysql_native_password' REQUIRE NONE PASSWORD"),
        start_with("CREATE USER `scott`@`localhost` IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE SSL WITH MAX_QUERIES_PER_HOUR 1 MAX_UPDATES_PER_HOUR 2 MAX_CONNECTIONS_PER_HOUR 3 MAX_USER_CONNECTIONS 4 PASSWORD"),
      ]
      expect(show_grants).to match_array [
        *grant_all_priv(user: 'bob', host: 'localhost'),
        "GRANT USAGE ON *.* TO 'scott'@'localhost' WITH GRANT OPTION",
      ].map { |str| str.gsub(/'/, '`') }
    end
  end
end

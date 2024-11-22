describe 'Gratan::Client#apply' do
  context 'when user does not exist' do
    subject { client }

    it do
      result = apply(subject) { '' }
      expect(result).to be_falsey
      expect(show_grants).to match_array []
    end
  end

  context 'when create user' do
    subject { client }

    it do
      # mysql>  SELECT CONCAT('*', UPPER(SHA1(UNHEX(SHA1('expected_password'))))) AS PASSWORD;
      # +-------------------------------------------+
      #   | PASSWORD                                  |
      #   +-------------------------------------------+
      #   | *EC698E653632EA2249F2346B3C4BC081F370BDAE |
      #   +-------------------------------------------+
      #   1 row in set (0.00 sec)
      quoted_expected_password = '*EC698E653632EA2249F2346B3C4BC081F370BDAE'
      result = apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'test.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end
end

user 'mary', '%', identified: "PASSWORD '#{quoted_expected_password}'" do
  on '*.*' do
    grant 'USAGE'
  end
end
        RUBY
      }

      expect(result).to be_truthy

      expect(show_create_users).to match_array [
        start_with("CREATE USER `scott`@`localhost` IDENTIFIED WITH 'mysql_native_password' AS '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' REQUIRE NONE PASSWORD EXPIRE"),
        start_with("CREATE USER `mary`@`%` IDENTIFIED WITH 'mysql_native_password' AS '#{quoted_expected_password}' REQUIRE NONE PASSWORD EXPIRE"),
      ]
      expect(show_grants).to match_array [
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
        "GRANT USAGE ON *.* TO 'mary'@'%'",
      ].normalize
    end
  end

  context 'when add user' do
    before do
      apply {
        <<-RUBY
user 'bob', '%', required: 'SSL' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end

  on 'test.*' do
    grant 'SELECT'
  end
end
        RUBY
      }
    end

    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'bob', '%', required: 'SSL' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end

  on 'test.*' do
    grant 'SELECT'
  end
end

user 'scott', 'localhost', identified: 'tiger' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'test.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        *grant_all_priv(user: 'bob', host: '%'),
        "GRANT SELECT ON `test`.* TO 'bob'@'%'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40'",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end

  context 'when create user with grant option' do
    subject { client }

    it do
      apply(subject) {
        <<-RUBY
user 'scott', 'localhost', identified: 'tiger' do
  on '*.*', with: 'grant option' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'test.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end
end
        RUBY
      }

      expect(show_grants).to match_array [
        "GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'scott'@'localhost' IDENTIFIED BY PASSWORD '*F2F68D0BB27A773C1D944270E5FAFED515A3FA40' WITH GRANT OPTION",
        "GRANT SELECT, INSERT, UPDATE, DELETE ON `test`.* TO 'scott'@'localhost'",
      ].normalize
    end
  end

  context 'when duplicata user' do
    subject { client }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end

  on 'test.*' do
    grant 'SELECT'
  end
end

user 'scott', 'localhost', identified: 'tiger' do
  on '*.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end

  on 'test.*' do
    grant 'SELECT'
    grant 'INSERT'
    grant 'UPDATE'
    grant 'DELETE'
  end
end
      RUBY

      expect {
        apply(subject) { dsl }
      }.to raise_error('User `scott@localhost` is already defined')
    end
  end

  context 'when duplicata object' do
    subject { client }

    it do
      dsl = <<-RUBY
user 'scott', 'localhost', required: 'SSL' do
  on '*.*' do
    grant 'ALL PRIVILEGES'
  end

  on '*.*' do
    grant 'SELECT'
  end
end
      RUBY

      expect {
        apply(subject) { dsl }
      }.to raise_error('User `scott@localhost`: Object `*.*` is already defined')
    end
  end
end

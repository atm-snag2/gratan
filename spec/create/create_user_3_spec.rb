describe 'Gratan::Client#apply' do
  context 'when create user' do
    subject { client(dry_run: true) }

    it do
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
        RUBY
      }

      expect(result).to be_falsey
      expect(show_create_users).to match_array []
      expect(show_grants).to match_array []
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

    subject { client(dry_run: true) }

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

      expect(show_create_users).to match_array [
        start_with("CREATE USER `bob`@`%` IDENTIFIED WITH 'mysql_native_password' REQUIRE SSL PASSWORD EXPIRE"),
      ]
      expect(show_grants).to match_array [
        *grant_all_priv(user: 'bob', host: '%'),
        user_host_normalize("GRANT SELECT ON `test`.* TO 'bob'@'%'"),
      ]
    end
  end

  context 'when create user with grant option' do
    subject { client(dry_run: true) }

    it do
      expect(show_create_users).to match_array []
      expect(show_grants).to match_array []

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

      expect(show_create_users).to match_array []
      expect(show_grants).to match_array []
    end
  end
end

$: << File.expand_path('..', __FILE__)

require 'gratan'
require 'tempfile'
require 'timecop'

IGNORE_USER = /\A((|root)\z|mysql\.)/
TEST_DATABASE = 'gratan_test'

RSpec.configure do |config|
  config.before(:each) do
    clean_grants
  end
end

def env_empty?(str)
  str.nil? || str.empty? || str == '0'
end

def mysql5_7?
  !env_empty?(ENV['MYSQL5_7']) || mysql8_0?
end

def mysql8_0?
  !env_empty?(ENV['MYSQL8_0'])
end

MYSQL_PORT = if ENV['MYSQL_PORT'].blank?
               3306
             else
               ENV['MYSQL_PORT'].to_i
             end

MYSQL_HOST = if ENV['MYSQL_HOST'].blank?
               '127.0.0.1'
             else
               ENV['MYSQL_HOST']
             end

MYSQL_USER = 'root'

def mysql
  client = nil
  retval = nil

  begin
    client = Mysql2::Client.new(host: MYSQL_HOST, username: MYSQL_USER, port: MYSQL_PORT)
    retval = yield(client)
  ensure
    client.close if client
  end

  retval
end

def create_database(client)
  client.query("CREATE DATABASE #{TEST_DATABASE}")
end

def drop_database(client)
  client.query("DROP DATABASE IF EXISTS #{TEST_DATABASE}")
end

def create_table(client, table)
  client.query("CREATE TABLE #{TEST_DATABASE}.#{table} (id INT)")
end

def create_function(client, func)
  client.query("CREATE FUNCTION #{TEST_DATABASE}.#{func}() RETURNS INT RETURN 1")
end

def create_procedure(client, prcd)
  client.query("CREATE PROCEDURE #{TEST_DATABASE}.#{prcd}() SELECT 1")
end

def create_tables(*tables)
  mysql do |client|
    begin
      drop_database(client)
      create_database(client)
      tables.each {|i| create_table(client, i) }
      yield
    ensure
      drop_database(client)
    end
  end
end

def create_functions(*funcs)
  mysql do |client|
    begin
      drop_database(client)
      create_database(client)
      funcs.each {|i| create_function(client, i) }
      yield
    ensure
      drop_database(client)
    end
  end
end

def create_procedures(*prcds)
  mysql do |client|
    begin
      drop_database(client)
      create_database(client)
      prcds.each {|i| create_procedure(client, i) }
      yield
    ensure
      drop_database(client)
    end
  end
end

def select_users(client)
  users = []

  client.query('SELECT user, host FROM mysql.user').each do |row|
    users << [row['user'], row['host']]
  end

  users
end

def clean_grants
  mysql do |client|
    select_users(client).each do |user, host|
      next if IGNORE_USER =~ user
      user_host =  "'%s'@'%s'" % [client.escape(user), client.escape(host)]
      client.query("DROP USER #{user_host}")
    end
  end
end

def show_create_users
  create_users = []

  mysql do |client|
    select_users(client).each do |user, host|
      next if IGNORE_USER =~ user
      user_host =  "'%s'@'%s'" % [client.escape(user), client.escape(host)]

      client.query("SHOW CREATE USER #{user_host}").each do |row|
        create_users << row.values.first
      end
    end
  end

  create_users.sort
end

def show_grants
  grants = []

  priv_re = Regexp.union(Gratan::GrantParser::STATIC_PRIVS)

  mysql do |client|
    select_users(client).each do |user, host|
      next if IGNORE_USER =~ user
      user_host =  "'%s'@'%s'" % [client.escape(user), client.escape(host)]

      client.query("SHOW GRANTS FOR #{user_host}").each do |row|
        grant = row.values.first
        grant_without_grant_option = grant.sub(/\s+WITH\s+GRANT\s+OPTION\z/, '')
        next unless priv_re.match?(grant_without_grant_option)
        grants << grant
      end
    end
  end

  grants.sort
end

def client(user_options = {})
  if user_options[:ignore_user]
    user_options[:ignore_user] = Regexp.union(IGNORE_USER, user_options[:ignore_user])
  end

  options = {
    host: MYSQL_HOST,
    username: MYSQL_USER,
    port: MYSQL_PORT,
    ignore_user: IGNORE_USER,
    logger: Logger.new('/dev/null'),
  }

  if mysql5_7?
    options.update(
      override_sql_mode: true,
      use_show_create_user: true,
    )
  end

  if ENV['DEBUG']
    logger = Gratan::Logger.instance
    logger.set_debug(true)

    options.update(
      debug: true,
      logger: logger
    )
  end

  options = options.merge(user_options)
  Gratan::Client.new(options)
end

def tempfile(content, options = {})
  basename = "#{File.basename __FILE__}.#{$$}"
  basename = [basename, options[:ext]] if options[:ext]

  Tempfile.open(basename) do |f|
    f.puts(content)
    f.flush
    f.rewind
    yield(f)
  end
end

def apply(cli = client)
  tempfile(yield) do |f|
    cli.apply(f.path)
  end
end

def grant_all_priv(user:, host: '%', database: '*', table: '*', auth: nil, required: 'SSL', with: nil)
  auth_clause = auth.blank? ? '' : " #{auth}"
  require_clause = required.blank? ? '' : " REQUIRE #{required}"
  with_clause = with.blank? ? '' : " WITH #{with}"

  if mysql8_0?
    all_privs = [
      'SELECT',
      'INSERT',
      'UPDATE',
      'DELETE',
      'CREATE',
      'DROP',
      'RELOAD',
      'SHUTDOWN',
      'PROCESS',
      'FILE',
      'REFERENCES',
      'INDEX',
      'ALTER',
      'SHOW DATABASES',
      'SUPER',
      'CREATE TEMPORARY TABLES',
      'LOCK TABLES',
      'EXECUTE',
      'REPLICATION SLAVE',
      'REPLICATION CLIENT',
      'CREATE VIEW',
      'SHOW VIEW',
      'CREATE ROUTINE',
      'ALTER ROUTINE',
      'CREATE USER',
      'EVENT',
      'TRIGGER',
      'CREATE TABLESPACE',
      'CREATE ROLE',
      'DROP ROLE',
    ]
    [
      "GRANT #{all_privs.join(', ')} ON #{database}.#{table} TO `#{user}`@`#{host}`#{with_clause}",
    ]
  else
    [
      "GRANT ALL PRIVILEGES ON #{database}.#{table} TO '#{user}'@'#{host}'#{auth_clause}#{require_clause}#{with_clause}",
    ]
  end
end

def create_user(user:, host: '%', database: '*', table: '*', identified: nil, password: nil, privs: nil, skip_create_user: false)
  if privs.nil?
    privs = ['USAGE']
  end
  if mysql8_0?
    identified_with = if !identified.nil?
                        " IDENTIFIED WITH mysql_native_password BY '#{identified}'"
                      else
                        ''
                      end
    sqls = [
      "CREATE USER '#{user}'@'#{host}'#{identified_with}",
      "GRANT #{privs.join(', ')} ON #{database}.#{table} TO '#{user}'@'#{host}'",
    ]
    if skip_create_user
      sqls[1..-1]
    else
      sqls
    end
  else
    identified_by = if !identified.nil?
                      %( IDENTIFIED BY '#{identified}')
                    elsif !password.nil?
                      %( IDENTIFIED BY PASSWORD '#{password}')
                    else
                      ''
                    end
    [
      "GRANT #{privs.join(', ')} ON #{database}.#{table} TO '#{user}'@'#{host}'#{identified_by}",
    ]
  end
end

def user_host_normalize(str)
  if mysql8_0?
    str.sub(/'([^']+)'@'([^']+)'/, '`\1`@`\2`')
  else
    str
  end
end

class Array
  def normalize
    if mysql5_7?
      self.map do |i|
        ii = i.sub(/ IDENTIFIED BY PASSWORD '[^']+'/, '')
          .sub(/ REQUIRE \w+\b/, '')
          .sub(/ WITH GRANT OPTION [\w ]+\z/, ' WITH GRANT OPTION')
        if mysql8_0?
          ii.sub(/'([^']+)'@'([^']+)'/, '`\1`@`\2`')
            .sub(/((?:\A| )GRANT )(.*?)( ON )/) do
              grant, body, on = $1, $2, $3
              new_body = body.split(/, /).map do |priv_type_columns|
                _, priv_type, cols = */\A([^\(]+)\(([^\)]+)\)\z/.match(priv_type_columns)
                if priv_type && cols
                  "#{priv_type}(#{cols.split(/, /).map { |c| "`#{c}`" }.join(', ')})"
                else
                  priv_type_columns
                end
              end.join(', ')
              "#{grant}#{new_body}#{on}"
            end
        else
          ii
        end
      end
    else
      self
    end
  end
end

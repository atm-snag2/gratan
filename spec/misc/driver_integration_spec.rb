require 'gratan'

describe 'Gratan::Driver integration', :skip_db_connection => true do
  before(:each) do
    # Skip the database cleanup for these tests
  end

  describe 'Client with version detection' do
    it 'automatically uses MySQL5 driver for MySQL 5.6' do
      client_mock = double('Mysql2::Client')
      allow(Mysql2::Client).to receive(:new).and_return(client_mock)
      allow(client_mock).to receive(:query).with('SELECT VERSION()').and_return([{'VERSION()' => '5.6.51'}])
      
      gratan_client = Gratan::Client.new(host: 'localhost', username: 'root')
      driver = gratan_client.instance_variable_get(:@driver)
      
      expect(driver).to be_a(Gratan::Driver::MySQL5)
    end

    it 'automatically uses MySQL57 driver for MySQL 5.7' do
      client_mock = double('Mysql2::Client')
      allow(Mysql2::Client).to receive(:new).and_return(client_mock)
      allow(client_mock).to receive(:query).with('SELECT VERSION()').and_return([{'VERSION()' => '5.7.42'}])
      
      gratan_client = Gratan::Client.new(host: 'localhost', username: 'root')
      driver = gratan_client.instance_variable_get(:@driver)
      
      expect(driver).to be_a(Gratan::Driver::MySQL57)
    end

    it 'automatically uses MySQL8 driver for MySQL 8.0' do
      client_mock = double('Mysql2::Client')
      allow(Mysql2::Client).to receive(:new).and_return(client_mock)
      allow(client_mock).to receive(:query).with('SELECT VERSION()').and_return([{'VERSION()' => '8.0.33'}])
      
      gratan_client = Gratan::Client.new(host: 'localhost', username: 'root')
      driver = gratan_client.instance_variable_get(:@driver)
      
      expect(driver).to be_a(Gratan::Driver::MySQL8)
    end

    it 'respects explicit driver_class option' do
      client_mock = double('Mysql2::Client')
      allow(Mysql2::Client).to receive(:new).and_return(client_mock)
      # Even though version is 5.6, we explicitly request MySQL8 driver
      
      gratan_client = Gratan::Client.new(
        host: 'localhost', 
        username: 'root',
        driver_class: Gratan::Driver::MySQL8
      )
      driver = gratan_client.instance_variable_get(:@driver)
      
      expect(driver).to be_a(Gratan::Driver::MySQL8)
    end
  end

  describe 'Exporter with different drivers' do
    it 'handles MySQL5 driver without show_create_user' do
      client_mock = double('Mysql2::Client')
      allow(client_mock).to receive(:escape) { |str| str }
      allow(client_mock).to receive(:query).with('SELECT VERSION()').and_return([{'VERSION()' => '5.6.51'}])
      allow(client_mock).to receive(:query).with('SELECT user, host FROM mysql.user').and_return([])
      
      driver = Gratan::Driver.new(client_mock, {})
      exporter = Gratan::Exporter.new(driver, {})
      
      expect { exporter.export }.not_to raise_error
    end

    it 'uses show_create_user with MySQL57 when option is enabled' do
      client_mock = double('Mysql2::Client')
      allow(client_mock).to receive(:escape) { |str| str }
      allow(client_mock).to receive(:query).with('SELECT VERSION()').and_return([{'VERSION()' => '5.7.42'}])
      allow(client_mock).to receive(:query).with('SELECT user, host FROM mysql.user').and_return(
        [{'user' => 'testuser', 'host' => 'localhost'}]
      )
      
      result_row = double('result_row')
      allow(result_row).to receive(:values).and_return(['CREATE USER statement'])
      result = double('result')
      allow(result).to receive(:first).and_return(result_row)
      
      allow(client_mock).to receive(:query).with("SHOW CREATE USER 'testuser'@'localhost'").and_return(result)
      allow(client_mock).to receive(:query).with("SHOW GRANTS FOR 'testuser'@'localhost'").and_return(
        [{'Grants' => "GRANT SELECT ON *.* TO 'testuser'@'localhost'"}]
      )
      
      driver = Gratan::Driver.new(client_mock, {})
      exporter = Gratan::Exporter.new(driver, {use_show_create_user: true})
      
      expect { exporter.export }.not_to raise_error
    end
  end
end

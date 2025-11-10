require 'gratan'

describe 'Gratan::Driver factory', :skip_db_connection => true do
  before(:each) do
    # Skip the database cleanup for these tests
  end

  describe '#detect_driver_class' do
    it 'detects MySQL 5.6' do
      client = double('Mysql2::Client')
      expect(client).to receive(:query).with("SELECT VERSION()").and_return([{'VERSION()' => '5.6.51'}])
      
      driver_class = Gratan::Driver.detect_driver_class(client, {})
      expect(driver_class).to eq(Gratan::Driver::MySQL5)
    end

    it 'detects MySQL 5.7' do
      client = double('Mysql2::Client')
      expect(client).to receive(:query).with("SELECT VERSION()").and_return([{'VERSION()' => '5.7.42'}])
      
      driver_class = Gratan::Driver.detect_driver_class(client, {})
      expect(driver_class).to eq(Gratan::Driver::MySQL57)
    end

    it 'detects MySQL 8.0' do
      client = double('Mysql2::Client')
      expect(client).to receive(:query).with("SELECT VERSION()").and_return([{'VERSION()' => '8.0.33'}])
      
      driver_class = Gratan::Driver.detect_driver_class(client, {})
      expect(driver_class).to eq(Gratan::Driver::MySQL8)
    end

    it 'allows explicit driver class specification' do
      client = double('Mysql2::Client')
      
      driver_class = Gratan::Driver.detect_driver_class(client, {driver_class: Gratan::Driver::MySQL8})
      expect(driver_class).to eq(Gratan::Driver::MySQL8)
    end
  end

  describe 'driver instantiation' do
    it 'creates MySQL5 driver for MySQL 5.6' do
      client = double('Mysql2::Client')
      expect(client).to receive(:query).with("SELECT VERSION()").and_return([{'VERSION()' => '5.6.51'}])
      
      driver = Gratan::Driver.new(client, {})
      expect(driver).to be_a(Gratan::Driver::MySQL5)
    end

    it 'creates MySQL57 driver for MySQL 5.7' do
      client = double('Mysql2::Client')
      expect(client).to receive(:query).with("SELECT VERSION()").and_return([{'VERSION()' => '5.7.42'}])
      
      driver = Gratan::Driver.new(client, {})
      expect(driver).to be_a(Gratan::Driver::MySQL57)
    end

    it 'creates MySQL8 driver for MySQL 8.0' do
      client = double('Mysql2::Client')
      expect(client).to receive(:query).with("SELECT VERSION()").and_return([{'VERSION()' => '8.0.33'}])
      
      driver = Gratan::Driver.new(client, {})
      expect(driver).to be_a(Gratan::Driver::MySQL8)
    end
  end

  describe 'driver version-specific features' do
    it 'MySQL5 driver returns nil for show_create_user' do
      client = double('Mysql2::Client')
      driver = Gratan::Driver::MySQL5.new(client, {})
      
      expect(driver.show_create_user('user', 'host')).to be_nil
    end

    it 'MySQL57 driver supports show_create_user' do
      client = double('Mysql2::Client')
      allow(client).to receive(:escape) { |str| str }
      result_row = double('result_row')
      allow(result_row).to receive(:values).and_return(['CREATE USER statement'])
      result = double('result')
      expect(result).to receive(:first).and_return(result_row)
      expect(client).to receive(:query).with("SHOW CREATE USER 'user'@'host'").and_return(result)
      
      driver = Gratan::Driver::MySQL57.new(client, {})
      expect(driver.show_create_user('user', 'host')).to eq('CREATE USER statement')
    end

    it 'MySQL8 driver supports show_create_user' do
      client = double('Mysql2::Client')
      allow(client).to receive(:escape) { |str| str }
      result_row = double('result_row')
      allow(result_row).to receive(:values).and_return(['CREATE USER statement'])
      result = double('result')
      expect(result).to receive(:first).and_return(result_row)
      expect(client).to receive(:query).with("SHOW CREATE USER 'user'@'host'").and_return(result)
      
      driver = Gratan::Driver::MySQL8.new(client, {})
      expect(driver.show_create_user('user', 'host')).to eq('CREATE USER statement')
    end
  end
end

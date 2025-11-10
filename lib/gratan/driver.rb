class Gratan::Driver
  def self.new(client, options = {})
    # Detect MySQL version and return appropriate driver
    driver_class = detect_driver_class(client, options)
    driver_class.new(client, options)
  end

  def self.detect_driver_class(client, options)
    # Allow explicit driver specification
    if options[:driver_class]
      return options[:driver_class]
    end

    # Auto-detect based on MySQL version
    version = client.query("SELECT VERSION()").first.values.first
    
    if version =~ /^8\./
      Gratan::Driver::MySQL8
    elsif version =~ /^5\.7/
      Gratan::Driver::MySQL57
    elsif version =~ /^5\./
      Gratan::Driver::MySQL5
    else
      # Default to MySQL5 for unknown versions
      Gratan::Driver::MySQL5
    end
  end
end

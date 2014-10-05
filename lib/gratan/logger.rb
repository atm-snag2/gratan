class Gratan::Logger < ::Logger
  include Singleton

  def initialize
    super($stdout)

    self.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    self.level = Logger::INFO
  end

  def set_debug(value)
    self.level = value ? Logger::DEBUG : Logger::INFO
  end

  module Helper
    def log(level, message, color = nil)
      options = @options || {}
      message = "[#{level.to_s.upcase}] #{message}" unless level == :info
      message << ' (dry-run)' if options[:dry_run]
      message = message.send(color) if color
      logger = options[:logger] || Gratan::Logger.instance
      logger.send(level, message)
    end
  end
end
require 'forwardable'

class Gratan::Client
  extend Forwardable

  delegate [:export, :apply] => :@client

  def initialize(options = {})
    @client = get_instance(options)
  end

  private

  def get_instance(options)
    client = Mysql2::Client.new(options)
    Gratan::Mysql5::Client.new(client, options)
  end
end

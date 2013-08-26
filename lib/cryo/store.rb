require 'logger'

class Store
  include Utils
  attr_accessor :logger

  def initialize(opts={})
    self.logger = Logger.new(STDERR)
    logger.level = Logger::DEBUG

    @snapshot_prefix    = opts[:snapshot_prefix]
    @time               = opts[:time]
  end

  def put
    raise NotImplementedError.new
  end

  class << self
    def create(options={})
      const_get(options[:type].to_s.capitalize).new(options)
    end
  end
end

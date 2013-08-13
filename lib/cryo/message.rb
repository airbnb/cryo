class Message
  def initialize(opts)
  end

  def get
    raise NotImplementedError.new
  end

  def put
    raise NotImplementedError.new
  end


  class << self
    def create(options={})
      message_class = const_get(options[:type].to_s.capitalize)
      message_class.new(options)
    end
  end
end


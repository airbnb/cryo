class Message

  def initialize(opts)
  end

  def get()
    raise "implement me"
  end

  def put()
    raise "implement me"
  end


  class << self
    def create(options={})
      message_class =  const_get(options[:type].to_s.capitalize)
      return message_class.new(options)
    end
  end

end


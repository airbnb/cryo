require 'cryo/utils'

class Database
  include Utils

  def get_backup
    raise NotImplementedError.new
  end

  class << self
    def create(options={})
      const_get(options[:type].to_s.capitalize).new(options)
    end
  end

end

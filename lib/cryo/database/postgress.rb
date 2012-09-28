# this has all of the logic to perform an entire dump of a remote postgress host

class Postgress

  attr_accessor :user, :host, :password, :local_path

  def initialize(opts={})
    raise "you need to specify a password" unless opts[:password]
    self.password = opts[:password]
    raise "you need to specify a host" unless opts[:host]
    self.host = opts[:host]
    self.user = opts[:user] || 'ubuntu'
    self.local_path = opts[:local_path] || get_tempfile
    verify_system_dependency 'pg_dumpall'
  end

  def backup!()
    take_dump
    compressed_file = gzip_file local_path
    put(file: compressed_file)
  end

  private

  ## perform a pg_dumpall to get an entire pgdump on the local system
  def take_dump()
    safe_run "PGPASSWORD=#{password} pg_dumpall --host=#{host} --username=#{user} --file=#{local_path}"
  end

end

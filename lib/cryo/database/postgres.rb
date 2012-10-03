# this has all of the logic to perform an entire dump of a remote postgress host

class Postgres
  include Utils
  attr_accessor :user, :host, :password, :local_path, :tmp_path

  def initialize(opts={})
    raise "you need to specify a password" unless opts[:password]
    self.password = opts[:password]
    raise "you need to specify a host" unless opts[:host]
    self.host = opts[:host]
    raise "you need to specify a tmp path" unless opts[:tmp_path]
    self.tmp_path = opts[:tmp_path]
    self.user = opts[:user] || 'ubuntu'
    self.local_path = opts[:local_path] || get_tempfile
    verify_system_dependency 'pg_dumpall'
  end

  def get_backup()
    take_dump
  end

  private

  ## perform a pg_dumpall to get an entire pgdump on the local system
  def take_dump()
    safe_run "PGPASSWORD=#{password} pg_dumpall --host=#{host} --username=#{user} --file=#{local_path}"
    local_path
  end

end

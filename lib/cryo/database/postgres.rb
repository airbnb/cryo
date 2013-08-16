# this has all of the logic to perform an entire dump of a remote postgres host

class Postgres
  include Utils
  attr_accessor :user, :host, :password, :local_path, :tmp_path

  def initialize(opts={})
    self.password   = opts[:password]   || raise('you need to specify a password')
    self.host       = opts[:host]       || raise('you need to specify a host')
    self.tmp_path   = opts[:tmp_path]   || raise('you need to specify a tmp path')
    self.user       = opts[:user]       || 'ubuntu'
    self.local_path = opts[:local_path] || get_tempfile
    verify_system_dependency 'pg_dumpall'
  end

  def get_backup
    safe_run "PGPASSWORD=#{password} pg_dumpall --host=#{host} --username=#{user} --file=#{local_path}"
    local_path
  end
end

# this has all of the logic to perform an entire dump of a remote postgres host

class Postgres
  include Utils
  attr_accessor :user, :host, :password, :local_path, :tmp_path, :database

  def initialize(opts={})
    self.password   = opts[:password]   || raise('you need to specify a password')
    self.host       = opts[:host]       || raise('you need to specify a host')
    self.tmp_path   = opts[:tmp_path]   || raise('you need to specify a tmp path')
    self.user       = opts[:user]       || 'ubuntu'
    self.local_path = opts[:local_path] || get_tempfile
    self.database   = opts[:database]

    if database
      verify_system_dependency 'pg_dump'
    else
      verify_system_dependency 'pg_dumpall'
    end
  end

  def get_backup
    if database
      get_backup_with_pg_dump
    else
      get_backup_with_pg_dumpall
    end

    local_path
  end

  private

  def get_backup_with_pg_dumpall
    safe_run "#{credentials} pg_dumpall #{backup_opts}"
  end

  def get_backup_with_pg_dump
    safe_run "#{credentials} pg_dump #{backup_opts} --format=plain #{database}"
  end

  def backup_opts
    "--host=#{host} --username=#{user} --file=#{local_path}"
  end

  def credentials
    "PGPASSWORD=#{password}"
  end
end

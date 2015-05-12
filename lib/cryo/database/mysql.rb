# this has all of the logic to perform an entire dump of a remote rds host

require 'tempfile'

class Mysql < Database
  include Utils
  attr_accessor :user, :host, :password, :local_path, :tmp_path, :port

  def initialize(opts={})
    self.password   = opts[:password]   || raise('you need to specify a password')
    self.host       = opts[:host]       || raise('you need to specify a host')
    self.tmp_path   = opts[:tmp_path]   || raise('you need to specify a tmp path')
    self.user       = opts[:user]       || 'ubuntu'
    self.port       = opts[:port]       || '3306'
    self.local_path = opts[:local_path] || get_tempfile
    verify_system_dependency 'mysqldump'
  end

  ## run through all of the necessary steps to perform a backup
  def get_backup(to_gzip = false)
    gzip_str = to_gzip ? '| gzip' : ''
    begin
      f = Tempfile.new(host, '/tmp')
      f.write("[client]\npassword=#{password}")
      f.close
      safe_run "mysqldump " \
          "--defaults-file=#{f.path} " \
          "--host=#{host} " \
          "--user=#{user} " \
          "--all-databases " \
          "--ignore-table=mysql.slow_log_backup " \
          "--ignore-table=mysql.slow_log " \
          "--single-transaction " \
          "#{gzip_str} > #{local_path}"
    ensure
      f.unlink
    end
    local_path
  end

  def get_gzipped_backup
    get_backup(true)
  end
end

# this has all of the logic to perform an entire dump of a remote rds host

class Mysql < Database

  include Utils
  attr_accessor :user, :host, :password, :local_path, :tmp_path, :port

  def initialize(opts={})
    raise "you need to specify a password" unless opts[:password]
    self.password = opts[:password]
    raise "you need to specify a host" unless opts[:host]
    self.host = opts[:host]
    raise "you need to specify a tmp path" unless opts[:tmp_path]
    self.tmp_path = opts[:tmp_path]
    self.user = opts[:user] || 'ubuntu'
    self.port = opts[:port] || '3306'
    self.local_path = opts[:local_path] || get_tempfile
    verify_system_dependency 'mysqldump'
  end

  ## run through all of the necessary steps to perform a backup
  def get_backup()
    get_dump
    local_path
  end
  
  def get_gzipped_backup
    get_and_gzip_dump
    local_path
  end

  private

  ## perform a mysqldump to get an entire mysql dump on the local system, while gzipping it at the same time
  def get_and_gzip_dump
    safe_run "mysqldump --host=#{host} --user=#{user} --password=#{password} --all-databases --single-transaction | gzip > #{local_path}"
  end

  ## perform a mysqldump to get an entire mysql dump on the local system
  def get_dump()
    safe_run "mysqldump --host=#{host} --user=#{user} --password=#{password} --all-databases --single-transaction > #{local_path}"
  end

end

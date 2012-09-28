# this has all of the logic to perform an entire dump of a remote rds host

class Mysql < Database

  attr_accessor :user, :host, :password, :local_path

  def initialize(opts={})
    raise "you need to specify a password" unless opts[:password]
    self.password = opts[:password]
    raise "you need to specify a host" unless opts[:host]
    self.host = opts[:host]
    self.user = opts[:user] || 'ubuntu'
    self.port = opts[:port] || '3306'
    self.local_path = opts[:local_path] || get_tempfile
    verify_system_dependency 'mysqldump'
  end

  ## run through all of the necessary steps to perform a backup
  def backup!()
    get_backup
    compressed_file = gzip_file local_path
    put(file: compressed_file)
  end

  private

  ## perform a mysqldump to get an entire mysql dump on the local system
  def get_dump()
    # TODO(martin): should we pass in the --lock-tables option?
    safe_run "echo #{password} | mysqldump --host=#{host} --user=#{user} --all-databases --password > #{local_path}"
  end

end

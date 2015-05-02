# this has all of the logic to perform an entire dump of a remote rds host

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

  def cnf_path
    "#{Dir.home}/#{host}.cnf"
  end

  def delete_cnf
    File.delete(cnf_path)
  end

  def write_cnf
    cnf = <<-EOF
[client]
password=#{password}
EOF
    File.open(cnf_path, 'w') { |f| f.write(cnf) }
    File.chmod(600, cnf_path)
  end

  ## run through all of the necessary steps to perform a backup
  def get_backup
    write_cnf
    begin
      safe_run "mysqldump --defaults-file=#{cnf_path} --host=#{host} --user=#{user} --all-databases --ignore-table=mysql.slow_log_backup --ignore-table=mysql.slow_log --single-transaction > #{local_path}"
    rescue => e
      delete_cnf
      throw e
    end
    delete_cnf
    local_path
  end

  def get_gzipped_backup
    write_cnf
    begin
      safe_run "mysqldump --defaults-file=#{cnf_path} --host=#{host} --user=#{user} --all-databases --ignore-table=mysql.slow_log_backup --ignore-table=mysql.slow_log --single-transaction | gzip > #{local_path}"
    rescue => e
      delete_cnf
      throw e
    end
    delete_cnf
    local_path
  end
end

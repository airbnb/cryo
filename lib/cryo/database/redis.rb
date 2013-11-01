class Redis
  include Utils
  attr_accessor :user, :host, :remote_path, :local_path, :tmp_path

  def initialize(opts={})
    self.host        = opts[:host]       || raise('you need to specify a remote host')
    self.tmp_path    = opts[:tmp_path]   || raise('you need to specify a tmp path')
    self.remote_path = opts[:path]       || '/mnt/redis/dump.rdb'
    self.user        = opts[:user]       || 'ubuntu'
    self.local_path  = opts[:local_path] || get_tempfile
  end

  ## get a copy of the db from remote host
  def get_backup
    safe_run "scp #{user}@#{host}:#{remote_path} #{local_path}"
    local_path
  end

  ## get a zipped copy of the db from remote host
  def get_gzipped_backup
    safe_run "ssh #{user}@#{host} gzip -c #{remote_path} > #{local_path}"
    local_path
  end

  private
  def ssh(command)
    safe_run "ssh #{user}@#{host} #{command}"
  end
end

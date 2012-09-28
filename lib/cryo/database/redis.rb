class Redis
  include Utils
  attr_accessor :user, :host, :remote_path, :local_path, :opts

  def initialize(opts={})
    raise "you need to specify a remote host" unless opts[:host]
    self.host = opts[:host]
    self.user = opts[:user] || 'ubuntu'
    self.remote_path = opts[:remote_path] || '/mnt/redis/dump.rdb'
    self.local_path = opts[:local_path] || get_tempfile
  end


  ## run through all of the necessary steps to perform a backup
  def get_backup()
    take_dump
  end

  private

  ## copy the redis db into a new file and scp it here
  def take_dump()
    # TODO(martin): verify that both the local and remote hosts have enough free disk space for this to complete
    temp_file = remote_path + "-backup-#{rand 99999}"
    ssh "cp #{remote_path} #{temp_file}"
    safe_run "scp #{user}@#{host}:#{temp_file} #{local_path}"
    ssh "rm -f #{temp_file}"
    local_path
  end


  def ssh(command)
    safe_run "ssh #{user}@#{host} #{command}"
  end

end

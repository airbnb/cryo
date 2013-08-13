class Redis
  include Utils
  attr_accessor :user, :host, :remote_path, :local_path, :opts, :tmp_path

  def initialize(opts={})
    self.host        = opts[:host]       || raise('you need to specify a remote host')
    self.tmp_path    = opts[:tmp_path]   || raise('you need to specify a tmp path')
    self.remote_path = opts[:path]       || '/mnt/redis/dump.rdb'
    self.user        = opts[:user]       || 'ubuntu'
    self.local_path  = opts[:local_path] || get_tempfile
  end


  ## get a copy of the db from remote host
  def get_backup
    take_dump
  end


  ## get a zipped copy of the db from remote host
  def get_gzipped_backup
    take_dump_and_gzip
  end

  private

  ## copy the redis db into a new file and scp it here
  def take_dump
    # TODO(martin): verify that both the local and remote hosts have enough free disk space for this to complete
    temp_file = remote_path + "-backup-#{rand 99999}"
    # this is kinda hacky, but we need to make sure that we remove a backup if we take one
    begin
      ssh "cp #{remote_path} #{temp_file}"
      safe_run "scp #{user}@#{host}:#{temp_file} #{local_path}"
    ensure
      ssh "rm -f #{temp_file}"
    end
    local_path
  end


  ## copy the redis db into a new file and stream it here while zipping
  def take_dump_and_gzip
    # TODO(martin): verify that both the local and remote hosts have enough free disk space for this to complete
    temp_file = remote_path + "-backup-#{rand 99999}"
    # this is kinda hacky, but we need to make sure that we remove a backup if we take one
    begin
      ssh "cp #{remote_path} #{temp_file}"
      safe_run "(ssh #{user}@#{host} cat #{temp_file}) | gzip > #{local_path}"
    ensure
      ssh "rm -f #{temp_file}"
    end
    local_path
  end


  def ssh(command)
    safe_run "ssh #{user}@#{host} #{command}"
  end
end

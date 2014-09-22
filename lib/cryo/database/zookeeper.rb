class Zookeeper
  include Utils

  attr_accessor :user, :host, :tmp_path, :remote_data_dir, :remote_txlog_dir

  def initialize(opts={})
    self.host = opts[:host] || raise('you need to specify a remote host')
    self.user = opts[:user] || 'ubuntu'

    self.tmp_path = opts[:tmp_path] || raise('you need to specify a tmp path')

    self.remote_data_dir = opts[:remote_data_dir] || raise('you need to specify a remote data dir')
    self.remote_txlog_dir = opts[:remote_txlog_dir] || raise('you need to specify a remote txlog dir')

    self.local_tmpdir = get_tempdir
  end

  def get_backup
    _get_backup "cat"
  end

  def get_gzipped_backup
    _get_backup "gzip -c"
  end

  private
  def _get_backup(cat)
    # Grab the latest snapshot and log filenames from Zookeeper
    filenames = safe_run "ssh #{user}@#{host} \"ls -1t #{remote_data_dir}/snapshot.* | head -1; ls -1t #{remote_txlog_dir}/log.* | head -1\"".split("\n")
    if filenames.length < 2
      raise "Didn't get enough filenames when looking in remote data+txlog directories"
    end
    filenames.each do |filename|
      unless filename.include?('snapshot.') or filename.include?('log.')
        raise "Bad filename #{filename}, doesn't look like a snapshot or txlog"
      end
      # name it locally the same thing as the remote filename, because
      # the filename encodes the zxid
      local_filename = File.join(local_tmpdir, filename.split('/')[-1])
      safe_run "ssh #{user}@#{host} \"#{cat} #{filename}\" > #{local_filename}"
    end
    tar_file = get_tempfile
    safe_run "tar -c -f #{tar_file} #{local_tmpdir}/* >/dev/null"
    tar_file
  end
end

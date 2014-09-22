class Filesystem < Database
  include Utils

  attr_accessor :tar_dir, :name

  def initialize(opts={})
    self.tar_dir = opts[:tar_dir] || raise('you need to specify a tar-dir')
  end

  ## get a copy of the db from remote host
  def get_backup
    tar_file = get_tempfile
    safe_run "tar -cf #{tar_file} #{tar_dir}/*"
    tar_file
  end

  ## get a zipped copy of the db from remote host
  def get_gzipped_backup
    tar_file = get_tempfile
    safe_run "tar -czf #{tar_file} #{tar_dir}/*"
    tar_file
  end

  private
end

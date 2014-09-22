require 'zlib'
require 'fileutils'
require 'time'
require 'tempfile'

module Utils
  def delete_file(path)
    File.delete(path) if File.exists?(path)
  end

  def get_tempfile
    tmp_file = Tempfile.new('cryo', @tmp_path)
    path = tmp_file.path
    tmp_file.close
    at_exit {delete_file path}
    path
  end

  def get_tempdir
    # ruby standard library doesn't wrap `mkdtemp`, so let's fake it
    tmp_file = Tempfile.new('cryo', @tmp_path)
    path = tmp_file.path
    tmp_file.close
    tmp_file.unlink
    FileUtils.mkdir_p(path)
    at_exit {FileUtils.rm_rf path}
    path
  end

  def gzip_file(path)
    # given a path to a file, return a gzipped version of it
    tempfile = get_tempfile
    #logger.info "gzipping #{path} to #{tempfile}"

    # stream the gzipped content into a file as we compute it
    Zlib::GzipWriter.open(tempfile) do |gz|
      File.open(path) do |f|
        # write 1M chunks at a time
        gz.write f.read(1024*1024) until f.eof?
      end
    end
    #logger.info "done unzipping"
    tempfile
  end

  def safe_run(command)
    #logger.debug "about to run #{command}"
    puts "about to run #{command}"
    output = `bash -c "set -o pipefail && #{command}"`.chomp
    raise "command '#{command}' failed!\nOutput was:\n#{output}" unless $?.success?
    output
  end

  def verify_system_dependency(command)
    raise "system dependency #{command} is not installed" unless system "which #{command} > /dev/null"
  end

  def get_utc_time_from_key_name(key_name)
    logger.debug "getting time for #{key_name}"
    year,month,day,time = key_name.split('/')
    hour,min,sec = time.split(':')
    Time.utc(year,month,day,hour,min,sec)
  end

  # returns the age of the snapshot in mins
  def get_age_from_key_name(key_name)
    snapshot_time = get_utc_time_from_key_name(key_name)
    age_in_mins_as_float = (@time - snapshot_time) / 60
    age_in_mins_as_float.to_i
  end
end

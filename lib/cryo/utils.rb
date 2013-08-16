require 'zlib'
require 'fileutils'
require 'time'

module Utils

  def delete_file(path)
    File.delete(path) if File.exists?(path)
  end

  def get_tempfile
    #    Tempfile.new('redis-backup','/mnt/cryo').path
    tmp_file = File.join(@tmp_path,"tmp-#{rand 9999}")
    at_exit {delete_file tmp_file}
    FileUtils.touch tmp_file
    tmp_file
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
    output = `bash -c "set -o pipefail && #{command}"`.chomp
    raise "command '#{command}' failed!\nOutput was:\n#{output}" unless $?.success?
    true
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

  # find out if we have an archive that is more recent than the snapshot period
  def need_to_archive?(old_snapshot_age,new_archive_age)
    logger.debug 'checking to see if we should archive'
    logger.debug "oldest snapshot age is #{old_snapshot_age}"
    logger.debug "newest archive time is #{new_archive_age}"
    logger.debug "@snapshot_period is #{@archive_frequency}"
    answer = (new_archive_age - old_snapshot_age) > @archive_frequency
    logger.debug "returning #{answer.inspect}"

    answer
  end
end

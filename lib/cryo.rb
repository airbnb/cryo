require 'aws-sdk'
require 'logger'
require 'json'

require 'cryo/utils'
require 'cryo/version'

require 'cryo/database'
require 'cryo/database/mysql'
require 'cryo/database/postgres'
require 'cryo/database/redis'

require 'cryo/store'
require 'cryo/store/s3'

class Cryo
  include Utils
  attr_accessor :options, :s3, :md5, :logger, :key

  def initialize(options={})
    self.options = options
    self.logger  = Logger.new(STDERR)
    logger.level = Logger::DEBUG

    @start_time         = Time.now.utc
    @start_timestamp    = @start_time.strftime('%Y/%m/%d/%H:%M:%S')
    @database = Database.create(options) \
      unless options[:type] == 'list' or options[:type] == 'get'
    @store              = Store.create(options.merge(type: 's3', time: @start_time))
    @snapshot_prefix    = options[:snapshot_prefix]
    @tmp_path           = options[:tmp_path]
    @report_path        = options[:report_path]
    @key                = "#{@snapshot_prefix}#{@start_timestamp}Z.cryo"
    @start_time         = Time.now.utc
    @start_timestamp    = @start_time.strftime('%Y/%m/%d/%H:%M:%S')

    @uncompressed_time, @backed_up_time, @stored_time = nil
    @uncompressed_size, @compressed_size = nil
  end

  def backup!
    if @database.respond_to? 'get_gzipped_backup'
      logger.info 'getting compressed backup'
      compressed_backup = @database.get_gzipped_backup
      @compressed_size = File.size compressed_backup
      @backed_up_time = Time.now.utc
      logger.info "got compressed backup in #{(@backed_up_time - @start_time).round 2} seconds"
    else
      logger.info 'taking backup...'
      backup_file = @database.get_backup
      @uncompressed_size = File.size backup_file
      @uncompressed_time = Time.now.utc
      logger.info "got backup in #{(Time.now.utc - @start_time).round 2} seconds"

      logger.info 'compressing backup...'
      compressed_backup = gzip_file backup_file
      @compressed_size = File.size compressed_backup
      @backed_up_time = Time.now.utc
      logger.info "compressed backup in #{(@backed_up_time - @uncompressed_time).round 2} seconds"
    end

    logger.info 'storing backup...'
    @store.put(
      content: Pathname.new(compressed_backup),
      bucket: options[:snapshot_bucket],
      key: @key
    )
    @stored_time = Time.now.utc
    logger.info "upload took #{(@stored_time - @backed_up_time).round 2} seconds"

    logger.info "completed entire backup in #{(@stored_time - @start_time).round 2} seconds :)"
  end

  def report
    {
      start_time:        @start_time.to_f,
      uncompressed_time: @uncompressed_time.to_f,
      backed_up_time:    @backed_up_time.to_f,
      stored_time:       @stored_time.to_f,
      compressed_size:   @compressed_size,
      uncompressed_size: @uncompressed_size
    }.delete_if do |k, v|
      v == 0 and k.to_s.end_with? '_time'
    end.to_json
  end

  def write_report
    IO::write @report_path, report if @report_path
  end
end

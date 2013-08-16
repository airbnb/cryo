require 'aws-sdk'
require 'logger'

## require all ruby files recursively
Dir.glob(File.join(File.dirname(__FILE__),'**/*.rb')).sort.each do |file|
  require_relative file
end

class Cryo
  include Utils
  attr_accessor :options, :s3, :md5, :sns, :logger, :key

  def initialize(options={})
    self.options = options
    self.logger  = Logger.new(STDERR)
    logger.level = Logger::DEBUG

    @time ||= get_utc_time  # don't change the endpoint!!!
    @timestamp ||= @time.strftime('%Y/%m/%d/%H:%M:%S')

    @database = Database.create(options) \
      unless options[:type] == 'list' or options[:type] == 'get'
    @store              = Store.create(options.merge(type: 's3', time: @time))
    @message            = Message.create(options.merge(type: 'sns'))
    @snapshot_prefix    = options[:snapshot_prefix]
    @archive_prefix     = options[:archive_prefix]
    @snapshot_frequency = options[:snapshot_frequency]
    @archive_frequency  = options[:archive_frequency]
    @snapshot_period    = options[:snapshot_period]
    @snapshot_bucket    = options[:snapshot_bucket]
    @archive_bucket     = options[:archive_bucket]
    @tmp_path           = options[:tmp_path]
    @report_path        = options[:report_path]
    @key                = "#{@snapshot_prefix}#{@timestamp}Z.cryo"
  end

  def backup!
    report = {}

    if @database.respond_to? 'get_gzipped_backup'
      logger.info 'getting compressed backup'
      compressed_backup = @database.get_gzipped_backup
      logger.info "got backup in #{(get_utc_time - @time).round 2} seconds"
    else
      logger.info 'taking backup...'
      backup_file = @database.get_backup
      logger.info "got backup in #{(get_utc_time - @time).round 2} seconds"

      timer = get_utc_time
      logger.info 'compressing backup...'
      compressed_backup = gzip_file backup_file
      logger.info "compressed backup in #{(get_utc_time - timer).round 2} seconds"
    end

    timer = get_utc_time
    logger.info 'storing backup...'
    @store.put(content: Pathname.new(compressed_backup), bucket: options[:snapshot_bucket],key: @key)
    logger.info "upload took #{(get_utc_time - timer).round 2} seconds"

    logger.info "completed entire backup in #{(get_utc_time - @time).round 2} seconds :)"
  end

  def archive_and_purge
    logger.info 'archiving and purging...'
    @store.archive_and_purge()
    logger.info 'done archiving and purging :)'
  end

  def list_snapshots
    snapshot_list = @store.get_bucket_listing(bucket: @snapshot_bucket, prefix: @snapshot_prefix)
    puts 'here is what I see in the snapshot bucket:'
    snapshot_list.each { |i| puts "  #{i.key}" }
  end

  def list_archives
    archive_list = @store.get_bucket_listing(bucket: @archive_bucket, prefix: @archive_prefix)
    puts 'here is what I see in the archive bucket:'
    archive_list.each { |i| puts "  #{i.key}" }
  end

  def get_snapshot(snapshot)
    basename = File.basename snapshot
    puts "getting #{snapshot} and saving it in #{File.join(Dir.pwd,basename)}"
    @store.get(bucket: @snapshot_bucket, key: snapshot, file: basename)
  end

end

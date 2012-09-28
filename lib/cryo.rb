require 'colorize'
require 'aws-sdk'
require 'logger'
require 'net/ntp'


## require all ruby files recursively
Dir.glob(File.join(File.dirname(__FILE__),'**/*.rb')).sort.each do |file|
  require_relative file
end


class Cryo 

  include Utils
#  HOST = `hostname`.chomp!
  attr_accessor :options, :s3, :md5, :sns, :logger, :key

  def initialize(options={})
    get_utc_timestamp # save start time for backup

    self.options = options
    self.logger = Logger.new(STDERR)
    logger.level = Logger::DEBUG

    @database = Database.create(options)
    @store = Store.create(options.merge(type: 's3',time: @time))
    @message = Message.create(options.merge(type: 'sns'))
    @snapshot_prefix = options[:snapshot_prefix]
    @archive_prefix = options[:archive_prefix]
    @key = get_timstamped_key_name
    @snapshot_frequency = options[:snapshot_frequency]
    @archive_frequency = options[:archive_frequency]
    @snapshot_period = options[:snapshot_period]
    @snapshot_bucket = options[:snapshot_bucket]
    @archive_bucket = options[:archive_bucket]
  end


  def backup!()
    logger.info "taking backup..."
    backup_file = @database.get_backup

    logger.info "compressing backup..."
    compressed_backup = gzip_file backup_file

    logger.info "storing backup..."
    @store.put(content: Pathname.new(compressed_backup), bucket: options[:snapshot_bucket],key: @key)

    logger.info "completed backup:)"
  end

  def archive_and_purge()
    logger.info "archiving and purging..."
    @store.archive_and_purge()
  end

  def list_snapshots
    snapshot_list = @store.get_bucket_listing(bucket: @snapshot_bucket, prefix: @snapshot_prefix)
    puts "here is what I see in the snapshot bucket:"
    snapshot_list.each { |i| puts "  #{i.key}"}
  end

  def list_archives
    archive_list = @store.get_bucket_listing(bucket: @archive_bucket, prefix: @archive_prefix)
    puts "here is what I see in the archive bucket:"
    archive_list.each { |i| puts "  #{i.key}"}
  end

end

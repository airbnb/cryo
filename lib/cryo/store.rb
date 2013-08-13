#require 'net/ntp'
require 'logger'

class Store

  include Utils
  attr_accessor :logger
  
  def initialize(opts={})
    self.logger = Logger.new(STDERR)
    logger.level = Logger::DEBUG

    @snapshot_frequency = opts[:snapshot_frequency]
    @archive_frequency  = opts[:archive_frequency]
    @snapshot_period    = opts[:snapshot_period]
    @snapshot_prefix    = opts[:snapshot_prefix]
    @archive_prefix     = opts[:archive_prefix]
    @time               = opts[:time]
  end

  def get
    raise NotImplementedError.new
  end

  def put
    raise NotImplementedError.new
  end

  def get_snapshot_list
    raise NotImplementedError.new
  end

  def get_archive_list
    raise NotImplementedError.new
  end

  class << self
    def create(options={})
      const_get(options[:type].to_s.capitalize).new(options)
    end
  end
  
  def archive_and_purge
    snapshot_list = get_snapshot_list
    newest_archive = get_newest_archive
    recursive_archive_and_purge(snapshot_list: snapshot_list, newest_archive: newest_archive)
  end

  protected

  def get_newest_archive
    raise NotImplementedError.new
  end


  def recursive_archive_and_purge(opts={})
    logger.debug 'entering recursive_archive_and_purge'
    snapshot_list = opts[:snapshot_list]

    # return if there are no snapshots
    if snapshot_list.empty?
      logger.info 'no snapshots found'
      return true 
    end

    # return if there are not enough snapshots avilable
    minium_number_of_snapshots = (@snapshot_period.to_f/@snapshot_frequency.to_f).ceil
    if snapshot_list.size < minium_number_of_snapshots
      logger.info 'not enough snapshots avilable for archiving'
      logger.info "we found #{snapshot_list.size} but we need to keep at least #{minium_number_of_snapshots}"
      return true
    end

    oldest_snapshot = snapshot_list.shift
    oldest_snapshot_age = get_age_from_key_name(oldest_snapshot)

    logger.debug "oldest_snapshot is #{oldest_snapshot}"
    logger.debug "oldest_snapshot_age is #{oldest_snapshot_age}"

    # return if the oldest snapshot it not old enough to be archived
    if oldest_snapshot_age < @snapshot_period
      logger.info 'all snapshots are younger than snapshot_period'
      return true 
    end

    # if we got this far, then the oldest snapshot needs to be either archived or deleted
    newest_archive = get_newest_archive

    # check to see if we have any archives
    if newest_archive.empty?
      logger.info 'looks like we don\'t have any archives yet'
      logger.info "archiving oldest snapshot #{oldest_snapshot}"
      archive_snapshot oldest_snapshot
      logger.debug 'recursing...'
      recursive_archive_and_purge(snapshot_list: snapshot_list, newest_archive: oldest_snapshot)
      return true
    end


    newest_archive_age = get_age_from_key_name(newest_archive)

    # check to see if the oldest snapshot should be archived
    if need_to_archive?(oldest_snapshot_age,newest_archive_age)
      logger.info "archiving oldest snapshot #{oldest_snapshot}"
      archive_snapshot oldest_snapshot
      logger.debug 'recursing...'
      recursive_archive_and_purge(snapshot_list: snapshot_list, newest_archive: oldest_snapshot)
      return true
    end

    # check the next oldest snapshot too, before we throw this one away
    second_oldest_snapshot = opts[:snapshot_list].first
    second_oldest_snapshot_age = get_age_from_key_name(second_oldest_snapshot)

    if need_to_archive?(second_oldest_snapshot_age,newest_archive_age)
      logger.info "archiving oldest snapshot #{oldest_snapshot}"
      archive_snapshot oldest_snapshot
      logger.debug 'recursing...'
      recursive_archive_and_purge(snapshot_list: snapshot_list, newest_archive: oldest_snapshot)
      return true
    end

    # if we got this far, then we just need to delete the oldest snapshot
    logger.info "deleting oldest snapshot #{oldest_snapshot}"
    delete_snapshot oldest_snapshot
    logger.debug 'recursing'
    recursive_archive_and_purge(snapshot_list: snapshot_list, newest_archive: newest_archive)
    true
  end
  
  def archive_snapshot snapshot
    raise NotImplementedError.new
  end

  def delete
    raise NotImplementedError.new
  end
end

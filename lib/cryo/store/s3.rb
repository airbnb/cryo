class S3 < Store
  require 'aws-sdk'
  
  attr_accessor :snapshot_bucket, :archive_bucket, :prefix

  def initialize(opts={})
    super(opts)
    AWS.config(:access_key_id => opts[:aws_access_key], 
               :secret_access_key => opts[:aws_secret_key])
    @s3 = AWS::S3.new
    @snapshot_bucket = @s3.buckets[opts[:snapshot_bucket]]
    @archive_bucket  = @s3.buckets[opts[:archive_bucket]]
  end

  def get(opts={})
    bucket = opts[:bucket]
    key = opts[:key]
    file_path = opts[:file] || opts[:path]
    if file_path
      File.open(file_path,'w') do |file|
        @s3.buckets[bucket].objects[key].read {|chunk| file.write chunk}
        return true
      end
    else
      @s3.buckets[bucket].objects[key].read
    end
  end

  
  def put(opts={})
    bucket = opts[:bucket]
    key = opts[:key]
    content = opts[:content]
    @s3.buckets[bucket].objects[key].write(content) # TODO: verify that bucket exists?
  end


  def etag(opts={})
    bucket = opts[:bucket]
    key = opts[:key]
    @s3.buckets[bucket].objects[key].etag
  end


  # return an array listing the objects in our snapshot bucket
  def get_snapshot_list
    get_bucket_listing(bucket: @snapshot_bucket, prefix: @prefix)
  end

 
  # return an array listing the objects in our archive bucket
  def get_archive_list
    get_bucket_listing(bucket: archive_bucket, prefix: @prefix)
  end

  # return an array listing of objects in a bucket
  def get_bucket_listing(opts={})
    bucket = opts[:bucket]
    prefix = opts[:prefix]
    list = []
    @s3.buckets[bucket].objects.with_prefix(prefix).each do |object|
      list << object
    end
    list
  end

  def get_snapshot_list
    snapshot_list = []
    @snapshot_bucket.objects.with_prefix(@snapshot_prefix).each do |object|
      snapshot_list << trim_snapshot_name(object.key)
    end
    snapshot_list
  end

  protected

  def expand_snapshot_name(shortname)
    @snapshot_prefix + shortname + 'Z.cryo'
  end

  def expand_archive_name(shortname)
    @archive_prefix + shortname + 'Z.cryo'
  end

  def trim_snapshot_name(longname)
    longname.gsub(/^#{@snapshot_prefix}/,'').gsub(/Z\.cryo$/,'')
  end

  def trim_archive_name(longname)
    return '' if longname.nil?
    longname.gsub(/^#{@archive_prefix}/,'').gsub(/Z\.cryo$/,'')
  end

  def delete_snapshot(snapshot)
    full_snapshot_name = expand_snapshot_name(snapshot)
    @snapshot_bucket.objects[full_snapshot_name].delete
  end

  def archive_snapshot(snapshot)
    logger.info "archiving snapshot #{snapshot}"
    full_snapshot_name = expand_snapshot_name(snapshot)
    full_archive_name = expand_archive_name(snapshot)
    logger.debug "full_snapshot_name is #{full_snapshot_name}"
    logger.debug "full_archive_name is #{full_archive_name}"
    snapshot_object = @snapshot_bucket.objects[full_snapshot_name]
    # if we have already copied the object, just delete the snapshot
    if @archive_bucket.objects[full_archive_name].exists?
      snapshot_object.delete
    else
      snapshot_object.move_to(full_archive_name, :bucket => @archive_bucket)
    end
  end
  

  # this function returns the last item in a bucket that matches the given prefix
  def get_newest_archive(prefix=@archive_prefix)
    tree = @archive_bucket.objects.with_prefix(prefix).as_tree
    directories = tree.children.select(&:branch?).collect(&:prefix)
    if directories.empty?
      matches = []
      @archive_bucket.objects.with_prefix(prefix).each {|o| matches << o.key}
      trim_archive_name(matches.last)
    else
      # recurse
      get_newest_archive(directories.last)
    end
  end
end

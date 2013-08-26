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
    bucket    = opts[:bucket]
    key       = opts[:key]
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
    bucket  = opts[:bucket]
    key     = opts[:key]
    content = opts[:content]
    @s3.buckets[bucket].objects[key].write(content) # TODO: verify that bucket exists?
  end

  def etag(opts={})
    bucket = opts[:bucket]
    key    = opts[:key]
    @s3.buckets[bucket].objects[key].etag
  end

  # return an array listing the objects in our snapshot bucket
  def list_snapshots
    @s3.buckets[@snapshot_bucket].objects.with_prefix(@prefix).to_a
  end

  protected

  def expand_snapshot_name(shortname)
    @snapshot_prefix + shortname + 'Z.cryo'
  end

  def trim_snapshot_name(longname)
    longname.gsub(/^#{@snapshot_prefix}/,'').gsub(/Z\.cryo$/,'')
  end

  def delete_snapshot(snapshot)
    full_snapshot_name = expand_snapshot_name(snapshot)
    @snapshot_bucket.objects[full_snapshot_name].delete
  end
end

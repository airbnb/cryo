class S3 < Store
  require 'aws-sdk'

  attr_accessor :snapshot_bucket, :archive_bucket, :prefix

  def initialize(opts={})
    super(opts)
    AWS.config(:access_key_id => opts[:aws_access_key],
               :secret_access_key => opts[:aws_secret_key])
    @s3 = AWS::S3.new
    @snapshot_bucket = @s3.buckets[opts[:snapshot_bucket]]
  end

  def put(opts={})
    bucket  = opts[:bucket]
    key     = opts[:key]
    content = opts[:content]
    # When using S3 cross-region replication across accounts
    # (https://docs.aws.amazon.com/AmazonS3/latest/dev/crr-how-setup.html)
    # it may be necessary to grant the destination account the
    # ACL read permissions for each object to provide read access
    options = { :grant_read => ENV['S3_ACL_GRANT_READ_GRANTEE'] }
    @s3.buckets[bucket].objects[key].write(content, options)
  end

  # return an array listing the objects in our snapshot bucket
  def list_snapshots
    @s3.buckets[@snapshot_bucket].objects.with_prefix(@prefix).to_a
  end
end

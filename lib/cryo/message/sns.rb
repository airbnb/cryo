class Sns < Message
  require 'aws-sdk'

  def initialize(opts={})
    AWS.config(:access_key_id     => opts[:aws_access_key],
               :secret_access_key => opts[:aws_secret_key])
    @sns   = AWS::SNS::Client.new
    @topic = opts[:topic] || opts[:topic_arn]
  end


  def send(opts={})
    @sns.publish({
      :message   => opts[:message],
      :subject   => opts[:subject],
      :topic_arn => @topic
    })
  end
end

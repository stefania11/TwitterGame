
class Tweet < ActiveRecord::Base
  include Key
  belongs_to :user

  @@client = Twitter::REST::Client.new do |config|
    config.consumer_key        = CONSUMER_KEY
    config.consumer_secret     = CONSUMER_SECRET
    config.access_token        = ACCESS_TOKEN
    config.access_token_secret = ACCESS_TOKEN_SECRET
  end



  def self.fetch_tweets_for(username)
    user = User.create(name: get_name(username))
    user.make_img_folder
    filter_tweets(username).each do |tweet|
      user.tweets.create(text: tweet)
    end
  end

  def self.get_name(username)
    @@client.user(username).name
  end

  def self.get_tweets(username)
    get_all_tweets(username).map {|tweet| tweet.text.gsub(/"/, '')}
  end

  def self.collect_with_max_id(collection=[], max_id=nil, &block)
    response = yield(max_id)
    collection += response
    response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
  end

  def self.get_all_tweets(username)
    collect_with_max_id do |max_id|
      options = {count: 200, include_rts: false}
      options[:max_id] = max_id unless max_id.nil?
      @@client.user_timeline(username, options)
    end
  end

  def self.filter_tweets(username)
    @filtered_tweets = get_tweets(username).delete_if do |tweet|
      tweet =~ /^@|http/
    end
  end
end

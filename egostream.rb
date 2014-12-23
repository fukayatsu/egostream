require 'dotenv'
Dotenv.load

require 'sinatra'
set :port, ENV['PORT'] || 80
get '/' do
  'ok'
end

Thread.new do
  require 'twitter'
  require 'slack-notifier'

  client = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = ENV['TWITTER_API_KEY']
    config.consumer_secret     = ENV['TWITTER_API_SECRET']
    config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
  end

  notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK_URL']

  puts 'start tracking'

  client.filter(track: ENV['TWITTER_TRACK'], language: ENV['TWITTER_LANGUAGE']) do |object|
    if object.is_a?(Twitter::Tweet)
      tweet = object
      next if tweet.retweet?
      screen_name = tweet.user.screen_name
      next if ENV['TWITTER_IGNORE_USERS'].split(',').include? screen_name
      p tweet.text
      notifier.ping "https://twitter.com/#{screen_name}/status/#{tweet.id}", icon_url: tweet.user.profile_image_url.to_s, username: screen_name
    end
  end
end

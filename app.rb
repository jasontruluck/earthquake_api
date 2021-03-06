# app.rb
require "rubygems"
require "sinatra"
require "sinatra/activerecord"
require "sinatra/redis"
require "resque"
require "open-uri"
require "csv"
require "time"
require "geocoder"
require "active_support/core_ext/time/calculations" # require for time for conversions on "on" calls
require "./config/environments"
require "./app/models/earthquake"
require "./app/jobs/import_job"

# Set the views directory under app
set :views, settings.root + '/app/views'

# Configure instance for redis & resque
configure do
  if settings.production?
    uri = URI.parse(ENV["REDISTOGO_URL"])
    Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    set :redis, ENV["REDISTOGO_URL"]
  end
end

# Provide information about the api
get "/" do
  haml :index
end

# Query the api
get "/earthquakes.json" do
  @earthquakes = Earthquake.filter(params)
  # Convert result to JSON with the number of results
  { :count => @earthquakes.count, :results => @earthquakes }.to_json
end

# Route for manually importing data on the fly
# This also queues up a recurring job if non exists
get "/import" do
  Earthquake.import
  redirect "/earthquakes.json"
end

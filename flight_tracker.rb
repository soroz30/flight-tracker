require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require 'tilt/erubis'
require "yaml"

use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: 'your_secret'

def compare_destinations(flight, data)
  [data[0], data[1]] == [flight[:departure], flight[:arrival]]
end

def check_date(flight, data)
  time = Time.parse(data[2])
  flight[:days].any? { |day| time.send("#{day}?") }
end

def check_airline(flight, data)
  return true if data[3].eql?("Any")
  flight[:airline] == data[3]
end

def select_flight(flight, data)
  compare_destinations(flight, data) &&
    check_date(flight, data) &&
    check_airline(flight, data)
end

def search_flights(data)
  flights = YAML.load_file("data/flights.yaml")
  flights.select { |_, flight| select_flight(flight, data) }
end

def calculate_date
  time = Time.new
  time.strftime("%Y-%m-%d")
end

def check_input(data)
  if data[0] == data[1]
    session[:message] = "You cannot choose the same airports"
    redirect "/"
  end
end

get "/" do
  @date = calculate_date
  erb :search
end

get "/search" do
  data = [params[:from], params[:to], params[:date], params[:airline]]
  check_input(data)
  @flights = search_flights(data)
  erb :results
end

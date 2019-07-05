#!/usr/bin/env ruby
# encoding: utf-8

require 'open-uri'

require 'bundler'
Bundler.require

require 'dotenv/load'

configure :development do
  require 'sinatra/reloader'
end

CONFIG = Struct \
  .new(:my_name, :coin_name, :coin_id, :amount, :currency, :round)
  .new(ENV['MY_NAME'], ENV['COIN_NAME'], ENV['COIN_ID'], ENV['AMOUNT'].to_f, ENV['CURRENCY'], ENV['ROUND'].to_i)

API_URL = "https://api.coinpaprika.com/v1/tickers/%{coin_id}?quotes=%{currency}"

def fetch_data
  url = API_URL % { coin_id: CONFIG.coin_id, currency: CONFIG.currency }
  whole_data = OpenURI.open_uri(url) { |io|JSON.parse(io.read) }
  whole_data['quotes'][CONFIG.currency]
end

def get_total(price)
  price * CONFIG.amount
end

def to_delimited(num, round = CONFIG.round)
  int, dec = num.round(round).to_s.split('.', 2)
  dec = dec.nil? ? '' : '.' + dec
  int.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,') + dec
end

get '/' do
  data = fetch_data
  erb :index, locals: {
    total:      to_delimited(get_total(data['price'])),
    change_24h: data['percent_change_24h'],
    change_7d:  data['percent_change_7d'],
    change_30d: data['percent_change_30d'],
    my_name:    CONFIG.my_name,
    coin_name:  CONFIG.coin_name,
    currency:   CONFIG.currency
  }
end

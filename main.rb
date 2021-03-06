#!/usr/bin/env ruby

require 'bundler'
Bundler.setup

require 'open-uri'
require 'json'
require 'awesome_print'
require 'date'
require 'cgi'
require 'i18n'

class String
  def dehumanize
    self.downcase.gsub(/[^\w\s]/, '').gsub(/\s+/, '-')
  end
end

def download_card_image(card)
  puts "Downloading card image for #{card['title']}"

  file_name = "#{ card['title'].dehumanize }.png"
  local_img_path = "img/#{ file_name }"
  image_url = "http://netrunnercards.info/#{ card['imagesrc'] }"

  open(image_url) do |input|
    open(local_img_path, 'w') do |out|
      out.write(input.read)
    end
  end

  file_name
end

SET_TERM = 'hap'
cards = []

# Grab card meta

url = "http://netrunnerdb.com/api/set/#{SET_TERM}"
puts url
runner_cards = open(url) do |f|
  cards.concat JSON.parse(f.read)
end

# Get a hash of card titles to their CardGameDB URLs

cgdb_card_urls = {}
CGDB_BASE_URL = 'http://www.cardgamedb.com/index.php/netrunner/android-netrunner-card-spoilers/_/'

# NOTE file scraped by sniffing traffic between the browser and CardGameDB
open 'cardgamedb-cards.json' do |io|
  cgdb_cards = JSON.load io
  cgdb_cards.each do |card|
    cgdb_card_urls[CGI.unescapeHTML(card['name'].downcase)] = "#{CGDB_BASE_URL}#{card['furl']}"
  end
end


# Download images

cards.each do |card|
  img_file_name = download_card_image(card)
  card['imagesrc'] = "/images/cards/#{img_file_name}"

  title = I18n.transliterate(card['title']).downcase

  # Typo correction
  title = 'alix t4lb07' if title == 'alix t4lbo7'

  if cgdb_card_urls[title].nil?
    puts "No CGDB URL found for #{card['title']}"
  end

  card['cgdb_url'] = cgdb_card_urls[title]
  card['nrdb_url'] = card.delete 'url'
  card.delete 'subtype_code'
  card.delete 'side_code'
  card.delete 'set_code'
  card.delete 'last-modified'
  card.delete 'faction_code'
  card.delete 'type_code'
  card.delete 'code'
  card.delete 'opinions'
  card.delete 'nbopinions'
  card.delete 'largeimagesrc'
end

open('cards.json', 'w') do |f|
  f.write(cards.to_json)
end

require 'bundler'
Bundler.setup

require 'open-uri'
require 'json'
require 'awesome_print'

class String
  def dehumanize
    self.downcase.gsub(/[^\w\s]/, '').gsub(/\s+/, '-')
  end
end

def download_card_image(card)
  puts "Downloading card image for #{card['title']}"

  local_img_path = "img/#{ card['title'].dehumanize }.png"
  image_url = "http://netrunnercards.info/#{ card['imagesrc'] }"

  open(image_url) do |input|
    open(local_img_path, 'w') do |out|
      out.write(input.read)
    end
  end

  card['imagesrc'] = local_img_path
end

cards = []

# Grab card meta

['d:r', 'd:c'].each do |term|
  runner_cards = open("http://netrunnercards.info/api/search/#{term}") do |f|
    cards.concat JSON.parse(f.read)
  end
end

# Download images

cards.each do |card|
  download_card_image(card)
end

open('cards.json', 'w') do |f|
  f.write(cards.to_json)
end

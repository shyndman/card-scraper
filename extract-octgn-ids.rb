#!/usr/bin/env ruby

require 'pathname'
require 'rubygems'
require 'nokogiri'
require 'json'

if ARGV.empty?
  $stderr.puts 'Usage: extract-octgn-ids {octgn project directory}'
  exit 1
end

cards = []
names_to_guids = {}

octgn = Pathname.new(ARGV.first)
octgn_sets = octgn + 'o8g/Sets/*/set.xml'
Dir.glob octgn_sets.to_s do |set_path|
  set_xml = Nokogiri::XML(open(set_path))
  cards += set_xml.css('card')
end

cards.each do |card|
  names_to_guids[card['name']] = card['id']
end

puts JSON.pretty_generate(names_to_guids)

require 'json'
require 'open-uri'
require 'i18n'
require 'time'

BASE_URL = 'http://www.reddit.com/r/Netrunner/search.json?q=CotD&restrict_sr=on&limit=100&sort=new&t=all'
OUT_PATH = 'reddit-cotds.json'

def write_out(cards)
  puts "Writing out cards to #{OUT_PATH}"
  open OUT_PATH, 'w' do |io|
    io.write cards.to_json
  end
end

# Grab all of the stories
cotds = JSON.load(open(BASE_URL))
stories = cotds['data']['children']

while !cotds['data']['after'].nil?
  cotds = JSON.load open("#{BASE_URL}&after=#{cotds['data']['after']}")
  stories += cotds['data']['children']
end

# Read cards.json locally
cards = JSON.load(open('reddit-cotds.json'))

# and mapify them
cards_by_title = {}
cards.each { |c| cards_by_title[I18n.transliterate(c['title']).downcase] = c  }

# Ask which stories are relevant
stories.each do |s|
  s_data = s['data']

  # Ask if relevant
  begin
    print s_data['title']
    print ' -- Relevant? (y/N/q) '
    ask_more = gets.strip.downcase
    if ask_more.length == 0 or ask_more == 'n'
      next
    elsif ask_more == 'q'
      break
    elsif ask_more != 'y'
      raise 'What?'
    end
  rescue
    retry
  end


  # Grab associated card names
  puts 'Attempting auto-match'
  possible_title = s_data['title'].gsub(/(\[[^\]]+\])/, '').gsub(/(\([^\)]+\))/, '').strip.downcase
  puts "Possible title: #{possible_title}"

  card_titles =
    if cards_by_title.key?(I18n.transliterate(possible_title))
      [possible_title]
    else
      puts 'No auto-match'
      begin
        puts 'Cards involved: (comma separated)'
        card_titles = gets.split(',').map(&:strip).map(&:downcase)
        card_titles.each do |name|
          if !cards_by_title.key?(I18n.transliterate(name))
            puts "#{name} not found. Try again"
            raise name
          end
        end
        card_titles
      rescue
        retry
      end
    end

  puts 'Match!'

  # Modify cards
  card_titles.each do |title|
    cotds = cards_by_title[I18n.transliterate(title)]['reddit_cotd'] ||= []

    if cotds.any? { |cotd| cotd['id'] == s_data['id'] }
      puts 'Duplicate found. Skipping...'
      next
    end

    cotds << {
      'id' => s_data['id'],
      'title' => s_data['title'],
      'url' => s_data['url'],
      'created' => Time.at(s_data['created_utc']).utc.iso8601
    }
  end
end

write_out(cards)

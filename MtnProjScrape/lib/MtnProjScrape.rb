require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'fileutils'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

# Testing method:
read_route_page('http://www.mountainproject.com/v/cassin-ridge/105954372')

DATA_DIR = 'data-hold/mountainProject'
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

BASE_URL = 'http://www.mountainproject.com'
INTERMEDIATE_URL = '/u/mark-p-thomas//106560803?action=ticks&&page='

# Page 1 is used as a starting point for getting the pagination range
URL_PAGE = '1'
LIST_URL = BASE_URL + INTERMEDIATE_URL + URL_PAGE

# Get the last page number from the second arrow button in the table navigation links in the first page
page = Nokogiri::HTML(open(LIST_URL))
last_page_number = page.css('a.smallMedium')[1]['href'].match(/page=(\d+)/)[1].to_i

# Get basic route data from route ticks
URL_ROUTES = []
puts "Iterating from 1 to #{last_page_number}"
(1..last_page_number).each { |pg_number|
  puts "Getting #{pg_number}"

  LIST_URL = BASE_URL + INTERMEDIATE_URL + pg_number
  route_ticks = read_route_ticks(LIST_URL)

  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/tick_list.txt"
  route_ticks.keys.each { |route_tick|  append_hash(local_fname, route_tick)}

  route_ticks.keys.each { |route_tick|  URL_ROUTES.push(BASE_URL + route_tick[:route_url]).compact.uniq}
} # done: pg_numbers.each

# Scrape remaining data from peak pages
URL_PARENTS = []
routes = {}
puts 'Iterating over route pages.'
URL_ROUTES.each do |url|
  route = read_route_page(url)
  routes[url] = route

  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/routes.txt"
  append_hash(local_fname, route)

  url_parent = BASE_URL + route[:parent_url]
  URL_PARENTS.push(url_parent).compact.uniq unless URL_ROUTES.include? url_parent
end # done: URL_ROUTES

puts 'Iterating over first parents.'
parents = {}
URL_PARENTS_PARENT = []
URL_PARENTS.each do |url|
  area = read_area_page(url)
  parents[url] = area

  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/areas.txt"
  append_hash(local_fname, area)

  ###########
  # For all parents up the tree
  parent_url = nil

  # Add to total list of parents
  url_parent = BASE_URL + area[:parent_url]
  URL_PARENTS_PARENT.push(url_parent).compact.uniq unless URL_PARENTS.include? url_parent
  # done: For all parents up the tree
end # done: URL_PARENTS

puts 'Iterating up route tree.'
URL_PARENTS_PARENT.each do |url|
  if parents.key?(url)
    next
  end

  area = read_area_page(url)
  parents[url] = area

  # Print to file. Later this is to be swapped to insert to database
  local_fname = "#{DATA_DIR}/areas.txt"
  append_hash(local_fname, area)
end # done: URL_PARENTS_TOTAL


def append_hash(local_fname, hash)
  hash.sort.each { |key, value|  File.open(local_fname, 'a'){|file| file.write(key + ': ' + value + "\n")}}
  File.open(local_fname, 'a'){|file| file.write("\n")}
end

def read_route_ticks(url)
  page = Nokogiri::HTML(open(url))
  rows = page.css('table.objectList > tr')

  route_ticks = {}
  rows[1..-2].each { |row|   # starting at 1 skips the column header
    route_tick = read_route_tick(row)
    route_ticks[route_tick[:route_url]] = route_tick
  } # done: rows.each

  route_ticks
end

def read_route_tick(row)
  route_name = row.css('td p')[0].content
  route_url = row.css('td p a')[0]['href']
  #route_stars = nil
  route_comments = row.css('td p.small')[1].content
  route_tick_date = row.css('td p.small')[2].content

  {route_name: route_name,
    route_url: route_url,
    route_comments: route_comments,
    route_tick_date: route_tick_date}
end

def read_todo(url)

end

def read_route_page(url)
  page = Nokogiri::HTML(open(url))

  route_name = page.css('h1.dkorange').content
  route_rating = nil
  route_stars = nil
  route_type = nil
  route_rating_original = nil
  route_description = nil

  parent_name = nil
  parent_url = nil

   {route_name: route_name,
     route_url: url,
     route_rating: route_rating,
     route_stars: route_stars,
     route_type: route_type,
     route_rating_original: route_rating_original,
     route_description: route_description,
     parent_name: parent_name,
     parent_url: parent_url}
end

def read_area_page(url)
  page = Nokogiri::HTML(open(url))

  name = nil

  latitude = nil
  longitude = nil

  description = nil
  getting_there = nil

  parent_name = nil
  parent_url = nil

  # For first parent
  {name: name,
    latitude: latitude,
    longitude: longitude,
    description: description,
    getting_there: getting_there,
    parent_name: parent_name,
    parent_url: parent_url}
end
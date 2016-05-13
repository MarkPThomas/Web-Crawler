require 'nokogiri'
require_relative '../lib/MtnProjScrape'
require_relative '../lib/LibFileReadWrite'

# Testing methods:
page1_data = read_route_page('http://www.mountainproject.com/v/cassin-ridge/105954372')
page2_data = read_route_page('http://www.mountainproject.com/v/chrysler-crack/105887571')
page3_data = read_route_page('http://www.mountainproject.com/v/centennial/105715670')
page4_data = read_area_page('http://www.mountainproject.com/v/swan-slab/105841123')
page5_data = read_area_page('http://www.mountainproject.com/v/california/105708959')
page6_data = read_routes_todo('http://www.mountainproject.com/u/mark-p-thomas//106560803?action=todos&')

# Running methods
DATA_DIR = 'data-hold/mountainProject'
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

BASE_URL = 'http://www.mountainproject.com'
PROFILE_URL = '/u/mark-p-thomas//106560803'

# Page 1 is used as a starting point for getting the pagination range
TICKS_URL = '?action=ticks&&page='
URL_PAGE = '1'
list_url = BASE_URL + PROFILE_URL + TICKS_URL + URL_PAGE

# Get the last page number from the second arrow button in the table navigation links in the first page
page = Nokogiri::HTML(open(list_url))
last_page_number = page.css('a.smallMedium')[1]['href'].match(/page=(\d+)/)[1].to_i

##### Ticks Page #####
# Get basic route data from route ticks
route_ticks = get_all_route_ticks(BASE_URL + PROFILE_URL + TICKS_URL, last_page_number)
url_routes = get_all_route_tick_urls(route_ticks)

# Read route pages to get stars and rating
get_all_ticked_route_overwrites(url_routes)

##### To-Do List Page #####
# Get additional routes from TODOS
puts 'Scraping To-Do Page'
TODO_URL = '?action=todos&'

list_url = BASE_URL + PROFILE_URL + TODO_URL
puts "Scraping: #{list_url}"
routes_todo = read_routes_todo(list_url)

# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/todo_list.txt"
puts "Writing to file #{local_fname}"
routes_todo.keys.each { |route_todo|  append_hash(local_fname, routes_todo[route_todo])}

puts 'Adding URLs to total routes URL list'
routes_todo.keys.each { |route_todo|  url_routes.push(BASE_URL + routes_todo[route_todo][:route_url]).compact.uniq}

##### Routes Page #####
# Scrape remaining data from route pages
routes = get_all_route_pages(url_routes)
url_parents = get_all_route_areas_urls(routes)

# Save complete URLs in case list needs to be regenerated - ideally from the backup file
# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/url_parents.txt"
puts "Writing to file #{local_fname}"
append_array(local_fname, url_parents)

##### Area Pages #####
areas = get_all_route_areas_pages(url_parents)
url_parents_parent = get_all_area_parents_urls(areas)

# Save complete URLs in case list needs to be regenerated - ideally from the backup file
# TODO
# Print to file. Later this is to be swapped to insert to database
local_fname = "#{DATA_DIR}/url_parents_parent.txt"
puts "Writing to file #{local_fname}"
append_array(local_fname, url_parents_parent)

get_all_area_parents_pages(url_parents_parent, areas)
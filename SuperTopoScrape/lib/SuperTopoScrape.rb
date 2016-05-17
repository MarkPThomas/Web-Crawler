require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative '../../lib/LibFileReadWrite'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/
# See: http://ruby.bastardsbook.com/chapters/mechanize/

BASE_URL = 'http://www.supertopo.com'
ROUTE_SEARCH_URL = '/routesearch.php'

# SuperTopo star ratings are on a scale of 0-5
MAX_STAR_RATING = 5

def search_route_reference(search_term)
  puts "Searching for route: #{search_term}"
  search_results = {}

  a = Mechanize.new { |agent|
    # Redirects after submission
    agent.follow_meta_refresh = true
  }

  a.get(BASE_URL + ROUTE_SEARCH_URL) { |search_page|

    my_results = search_page.form_with(:name => 'searchform'){ |form|
      form.ftr = search_term
    }.submit

    search_results = get_search_page_results(my_results)
  }
  search_results
end


def scrape_new(existing_urls, base_url, username, password)
# TODO
end

def scrape_all(username, password, data_dir)
  FileUtils::mkdir_p(data_dir) unless File.exists?(data_dir)

  report_summaries = get_profile_trip_reports(username, password)
  overwrite_sub_hashes(report_summaries, "#{data_dir}/reports_summaries.txt")

  report_urls = []
  report_summaries.keys.each { |report_summary|
    report_urls[report_urls.count] = report_summaries[report_summary][:report_url]
  }

  read_write_report_pages(report_urls, data_dir)
  puts 'Website scrape complete.'
end

# ================================
# Supporting Methods: Entry Points: Search Results
# ================================
def get_search_page_results(page)
  rows = page.parser.css('table.graybox > tr.stdrow')

  results = {}
  max_num = rows.count
  count = 1
  rows.each { |row|
    puts "Reading results row #{count} of #{max_num}"
    row_nodes = row.css('> td')

    row_nodes.count > 0 ? result_title = row_nodes[0].css('td')[1].css('a')[0].text : result_title = nil
    row_nodes.count > 0 ? result_url = row_nodes[0].css('td')[1].css('a')[0]['href'] : result_url = nil
    row_nodes.count > 1 ? result_formation = row_nodes[1].text : result_formation = nil
    row_nodes.count > 2 ? result_climbing_area = row_nodes[2].text : result_climbing_area = nil
    row_nodes.count > 3 ? pitch_number = row_nodes[3].text : pitch_number = nil
    row_nodes.count > 4 ? result_rating = row_nodes[4].text : result_rating = nil

    img_url = get_route_search_image(row)
    img_url.sub!(BASE_URL,'')

    result_stars = get_route_search_stars(row_nodes)
    !result_stars.nil? ? result_quality = result_stars.to_f / MAX_STAR_RATING : result_quality = nil

    results[result_url] = {result_title: result_title,
                          result_url: result_url,
                          img_url: img_url,
                          result_formation: result_formation,
                          result_climbing_area: result_climbing_area,
                          pitch_number: pitch_number,
                          result_rating: result_rating,
                          result_quality: result_quality}
    count += 1
  }
  results
end

def get_route_search_image(row_nodes)
  route_img_node = row_nodes.css('div.photo-route img')
  route_img_node.count > 0 ? route_img_node[0]['src'] : nil
end

def get_route_search_stars(row_nodes)
  if row_nodes.count > 5
    route_quality_node = row_nodes[5].css('img')
    route_quality_node.count > 0 ? route_quality_node[0]['alt'][0] : nil
  else
    nil
  end
end

# ================================
# Supporting Methods: Entry Points: Profile Page
# ================================

def get_profile_trip_reports(username, password)
  puts "Getting trip report summaries for #{username}"
  report_row_data = nil

  a = Mechanize.new { |agent|
    # SuperTopo redirects after login
    agent.follow_meta_refresh = true
  }

  a.get(BASE_URL) { |home_page|
    puts "Signing in to #{BASE_URL}"
    signin_page = a.click(home_page.link_with(:text => /Sign In/))

    my_page = signin_page.form_with(:name => 'editform') do |form|
      form.email  = username
      form.passwd = password
    end.submit

    # Click the profile page link
    puts 'Going to the profile page'
    profile_page = a.click(my_page.link_with(:text => /My Settings/))
    puts 'Going to the Trip Reports tab'
    trip_reports_page = a.click(profile_page.link_with(:text => /Your Trip Reports/))

    report_row_data = get_report_rows_values(trip_reports_page)
  }
  report_row_data
end

def get_report_rows_values(page)
  puts 'Reading Trip Report summary row data'
  report_row_data = {}

  # Light Rows
  rows = page.parser.css('table.graybox tr.lightrow')
  rows.each { |row|
    report_row_data_value = get_report_row_values(row)
    report_row_data[report_row_data_value[:report_url]] = report_row_data_value
  }

  # Dark Rows
  rows = page.parser.css('table.graybox tr.darkrow')
  rows.each { |row|
    report_row_data_value = get_report_row_values(row)
    report_row_data[report_row_data_value[:report_url]] = report_row_data_value
  }

  report_row_data
end

def get_report_row_values(row)
  puts 'Reading Trip Report summary'
  report_element = row.css('td > a')
  if report_element.nil?
    report_element = row.css('td a')[1]
  else
    report_element = report_element[0]
  end

  report_name = report_element.text
  report_url = report_element['href']
  id = get_report_id(report_url)
  hits = row.css('> td')[1].text
  messages = row.css('> td')[3].text

  {report_url:report_url,
   report_name: report_name,
   id: id,
   hits: hits,
   messages: messages}
end


# ================================
# Supporting Methods: Pages
# ================================
def read_write_report_pages(urls, data_dir)
  max_num = urls.count
  count = 1
  urls.each { |url|
    puts "Reading page #{count} of #{max_num}"
    report = read_report_page(BASE_URL + url)
    id = report[:id]
    overwrite_hash(report, "#{data_dir}/report_#{id}.txt")
    count += 1
  }
end

def read_report_page(url)
  puts "Reading Trip Report Page #{url}"
  page = Nokogiri::HTML(open(url))

  name = page.css('span.articleTitle').text
  id = get_report_id(url)
  content = page.css('div.articletext')

  {url: url.sub(BASE_URL,''),
   name: name,
   id: id,
   content: content}
end

def get_report_id(url)
  id = url.split('/').last
  id.sub!('.html','')
end


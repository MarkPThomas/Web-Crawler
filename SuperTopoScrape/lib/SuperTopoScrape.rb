require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
#require 'net/https'
#require 'net/http'
require 'fileutils'
#require 'restclient'
require_relative '../../lib/LibFileReadWrite'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/
# See: http://ruby.bastardsbook.com/chapters/mechanize/

def search_route_reference(search_term)
# TODO
  {}
end

def scrape_new(existing_urls, base_url, username, password)
# TODO
end

def scrape_all(base_url, username, password, data_dir)
  FileUtils::mkdir_p(data_dir) unless File.exists?(data_dir)

  report_summaries = get_profile_trip_reports(base_url, username, password)
  report_summaries.keys.each { |report_summary|
    append_hash("#{data_dir}/reports_summaries.txt", report_summaries[report_summary])
  }

  report_urls = []
  report_summaries.keys.each { |report_summary|
    report_urls[report_urls.count] = report_summaries[report_summary][:report_url]
  }

  read_write_report_pages(base_url, report_urls, data_dir)
  puts 'Website scrape complete.'
end

def get_profile_trip_reports(base_url, username, password)
  puts "Getting trip report summaries for #{username}"
  report_row_data = nil

  a = Mechanize.new { |agent|
    # SuperTopo redirects after login
    agent.follow_meta_refresh = true
  }

  a.get(base_url) do |home_page|
    puts "Signing in to #{base_url}"
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
  end
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

def read_write_report_pages(base_url, urls, data_dir)
  max_num = urls.count
  count = 1
  urls.each { |url|
    puts "Reading page #{count} of #{max_num}"
    report = read_report_page(base_url + url)
    id = report[:id]
    append_hash("#{data_dir}/report_#{id}.txt", report)
    count += 1
  }
end

def read_report_page(url)
  puts "Reading Trip Report Page #{url}"
  page = Nokogiri::HTML(open(url))

  name = page.css('span.articleTitle').text
  id = get_report_id(url)
  content = page.css('div.articletext')

  {url: url,
   name: name,
   id: id,
   content: content}
end

def get_report_id(url)
  id = url.split('/').last
  id.sub!('.html','')
end


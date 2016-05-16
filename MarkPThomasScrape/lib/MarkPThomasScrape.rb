require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative '../../lib/LibFileReadWrite'
require_relative '../../lib/LibParse'

# ================================
# Scraping: All
# ================================
def scrape_all(base_url, data_dir)
  FileUtils::mkdir_p(data_dir) unless File.exists?(data_dir)

  puts 'Running full scrape'
  page = Nokogiri::HTML(open(base_url))

  scrape_all_of_type('Trip_Report', 'gx:79f1adc80c2b95e', page, base_url, data_dir)
  scrape_all_of_type('Article', 'gx:90aabe2a4d48f8d', page, base_url, data_dir)

  puts 'Website scrape complete.'
end

def scrape_all_of_type(type, wuid, page, base_url, data_dir)
  puts "Scraping #{type} Menu Items"
  menu_items = read_page_menu_items(page, wuid, type)
  local_fname = "#{data_dir}/#{type}_Menu_Items.txt"
  puts 'Writing menu items'
  print_sub_hashes(menu_items, local_fname)

  puts "Scraping #{type} Pages"
  max_num = menu_items.count
  count = 1
  menu_items.each { |menu_item|
    puts "Scraping #{type} #{count} of #{max_num}"
    menu_item = add_page_data_to_menu_item(base_url, menu_item)
    print_menu_item(menu_item, data_dir) unless menu_item.nil?
    count += 1
  }
end


# ================================
# Supporting Methods: Entry Points
# ================================
def print_menu_item(report, data_dir)
  local_fname = "#{report[:type]}_#{report[:page_id]}.txt"
  append_hash("#{data_dir}/#{local_fname}", report)
end

def add_page_data_to_menu_item(base_url, report)
  report_page = read_page(base_url + report[1][:page_url])
  report_page.nil? ? nil : report[1].merge!(report_page)
end

def read_page_menu_items(page, wuid, type)
  puts "Reading menu items for wuid #{wuid}"
  nav = page.css('td#sites-chrome-sidebar-left')
  nav_items = nav.css("li[wuid='#{wuid}'] > ul[role=navigation] a")

  menu_items = {}
  page_id = 1
  max_num = nav_items.count
  nav_items.each { |nav_item|
    puts "Reading menu item #{page_id} of #{max_num}"
    menu_item = read_page_menu_item(nav_item)

    unless menu_item.nil?
      menu_item[:page_id] = page_id
      menu_item[:type] = type
      menu_items[menu_item[:page_url]] = menu_item
    end
    page_id += 1
  }
  menu_items
end

def read_page_menu_item(nav_item)
  page_url = nav_item['href']

  page_menu_name = nav_item.text
  page_menu_name = strip_bullet_point(page_menu_name) # Removes bullet point
  page_menu_name.gsub!(/\A{|}\Z/, '')                 # Removes any quotation marks
  page_menu_name.gsub!(/\A[|]\Z/, '')                 # Removes any quotation marks
  page_menu_name.gsub!(/\A"|"\Z/, '')                 # Removes any quotation marks
  page_menu_name.strip!

  {page_url: page_url,
   page_menu_name: page_menu_name}
end

# ================================
# Supporting Methods : Pages
# ================================
def read_page(url)
  begin
    puts "Reading page #{url}"
    page = Nokogiri::HTML(open(url))

    page_element = page.css('div#sites-canvas-main-content div[dir=ltr]')

    if page_element.nil?
      nil
    else
      title = page_element[0].css('h1')[0].text
      content = page_element[0]

      {title: title,
       content: content}
    end
  rescue
    nil
  end
end

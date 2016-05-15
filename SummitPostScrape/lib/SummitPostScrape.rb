require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'fileutils'
require_relative 'LibFileReadWrite'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

# SummitPost start ratings are on a scale of 0-5
MAX_STAR_RATING = 5

def read_write_climber_logs(urls, profile_url, dir)
  climber_logs = read_climber_log_pages(urls, profile_url)

  puts 'Writing all climber logs to file'
  climber_logs.keys.each { |log_page|
    climber_logs[log_page].each { |log|
      append_hash("#{dir}/climber_logs.txt", log[1])
    }
  }
end

def read_climber_log_pages(urls, profile_url)
  max_num = urls.count
  count = 0
  logs = {}
  urls.each { |url|
    puts "Reading climber log #{count} of #{max_num}"
    logs[url] = read_climbers_log_page(url, profile_url)
    count += 1
  }
  logs
end

def read_write_pages_personal(urls, dir)
  max_num = urls.count
  count = 0
  urls.each { |url|
    puts "Reading personal page #{count} of #{max_num}"
    page = Nokogiri::HTML(open(url))
    read_write_page_by_type(page, url, dir, 'my_')
    count += 1
  }
end

def read_write_pages_ticked(tick_urls, profile_url, dir)
  max_num = tick_urls.count
  count = 0
  tick_urls.each { |tick_url|
    puts "Reading ticked page #{count} of #{max_num}"
    tick_page_url = get_ticked_page_url(tick_url, profile_url)
    page = Nokogiri::HTML(open(tick_page_url))
    read_write_page_by_type(page, tick_page_url, dir)
    count += 1
  }
end

def get_ticked_page_url(tick_url, profile_url)
  logs = read_climbers_log_page(tick_url, profile_url)

  if logs.count > 0
    logs.values[0][:object_url]
  else
    nil
  end
end

def get_object_urls_from_profile(url)
  puts 'Getting URLs for object pages ...'
  page = Nokogiri::HTML(open(url))
  links = page.css('div.parent_search_list > a')

  object_link = {}
  links.each { |link|
    link_url = link['href']

    unless link_url.include? '/climbers-log/'
      link_name = link.text

      object_link[link_url] = {link_url: link_url,
                               link_name: link_name}
    end
  }
  object_link
end

def get_tick_urls_from_profile(url)
  puts 'Getting URLs for tick/log pages ...'
  page = Nokogiri::HTML(open(url))
  links = page.css('div.parent_search_list > a')

  tick_link = {}
  links.each { |link|
    link_url = link['href']

    if link_url.include? '/climbers-log/'
      link_name = link.text

      tick_link[link_url] = {link_url: link_url,
                             link_name: link_name}
    end
  }
  tick_link
end

def classify_page(page)
  puts 'Getting page classification ...'
  get_main_data_box_item(page,'Page Type: ')
end

def read_page_by_type(page, url)
  type = classify_page(page)

  puts "Reading page of type: #{type}"
  case type
    when 'Route', 'Mountain/Rock', 'Article', 'Trip Report', 'Area/Range', 'Trailhead', 'Canyon'
      read_page(page, url)
    else
      # Page is ignored
      nil
  end
end

def read_write_page_by_type(page, url, data_dir, prefix='')
  page_to_write = read_page_by_type(page, url)

  unless page_to_write.nil?
    type = page_to_write[:type]
    type.gsub!('/', '-')
    id = page_to_write[:id]
    puts "Writing page of type: #{type} for ID #{id}"
    append_hash("#{data_dir}/#{prefix}#{type}_#{id}.txt", page_to_write)
  end
end


def read_climbers_log_page(url, profile_url)
  puts "Reading climbers log page: #{url} \n  for climber #{profile_url}"
  page = Nokogiri::HTML(open(url))
  tables = page.css('table.messages')

  climber_log = {}
  tables.each { |table|
    user_tag = table.css('a.dis_user_lnk')
    user_tag.count > 0 ? user = user_tag[0]['href'] : user = nil

    if !user.nil? && user === profile_url
      climber_log[url] = read_climber_log(url, table)
    end
  }
  climber_log
end

def read_climber_log(url, table)
  puts 'Reading climber log'

  object_id = url.split('/climbers-log/')[1]
  object_id = object_id.split('/d-')[0]

  object_url = url.split('/climbers-log/')[0] + '/' + object_id

  title = table.css('tr > td > b')[0].text
  route_name = get_route(title)
  date = get_date(table)
  success = get_success(table)
  message = table.css('tr')[1].css('td')[1].text

  {id: object_id,
   object_url: object_url,
   route_name: route_name,
   log_url: url,
   title: title,
   success: success,
   date: date,
   message: message}
end

def get_route(title)
  begin
    route_key = 'Route Climbed: '
    date_key = 'Date Climbed: '

    route = nil
    if title.include? date_key
      titles = title.split(date_key)
      titles.each { |split_title|
        route = split_title if split_title.include? route_key
      }
    else
      route = 'N/A'
    end

    if !route.nil? && (route.include? route_key)
      route.sub!(route_key, '')
    elsif title.include? route_key
      route = title.sub!(route_key, '')
    else
      route = nil
    end
  rescue
    route = nil
  end
  route
end

def get_date(table)
  begin
    # Some logs have the date in the title.
    # Other logs have a particular span element with the title.

    title = table.css('tr > td > b')[0].text
    date_key = 'Date Climbed: '
    date = nil
    if title.include? date_key
      titles = title.split(date_key)
      date = titles.last
    else
      date = table.css('tr > td > span')[0].text
      date.sub!(/^Date Climbed: /,'').strip!
    end
  rescue
    date = nil
  end
  date
end

def get_success(table)
  begin
    nk_element = table.css('a[title]')
    if nk_element.count > 0
      nk_element[0]['title']
    else
      'No'
    end
  rescue
    'Unknown'
  end
end

def read_page(page, url)
  puts "Reading page: #{url}"

  id = url.split('/').last
  name = get_main_data_box_item(page,'Object Title: ')
  type = classify_page(page)

  location = get_main_data_box_item(page,'Location: ')

  lat_long = get_main_data_box_item(page,'Lat/Lon: ')
  latitude = get_latitude(lat_long)
  longitude = get_longitude(lat_long)

  elevation = get_elevation(page)

  route_type = get_main_data_box_item(page,'Route Type: ')
  seasons = get_main_data_box_item(page,'Season: ')
  time_required = get_main_data_box_item(page,'Time Required: ')
  rock_difficulty = get_main_data_box_item(page,'Rock Difficulty: ')
  difficulty = get_main_data_box_item(page,'Difficulty: ')
  number_of_pitches = get_main_data_box_item(page,'Number of Pitches: ')
  grade = get_main_data_box_item(page,'Grade: ')

  route_quality = get_rating(page)
  my_route_quality = get_my_rating(page)

  activities = get_main_data_box_item(page,'Activities: ')
  date = get_main_data_box_item(page,'Date Climbed/Hiked: ')

  content = page.css('article')

   {id: id,
    page_url: url,
    name: name,
    type: type,
    location: location,
    latitude: latitude,
    longitude: longitude,
    elevation: elevation,
    route_type: route_type,
    seasons: seasons,
    time_required: time_required,
    rock_difficulty: rock_difficulty,
    difficulty: difficulty,
    number_of_pitches: number_of_pitches,
    grade: grade,
    route_quality: route_quality,
    my_route_quality: my_route_quality,  # Currently this always come back as nil, because the css element hasn't loaded at the time that Nokogiri gets the page :-()
    activities: activities,
    date: date,
    content: content}
end

def get_latitude(lat_long)
  puts "Getting latitude: #{lat_long}"
  begin
    latitude_s = lat_long.split(' / ')[0]
    if latitude_s.include? 'N'
      latitude_s[0...-2].to_f
    else
      latitude_s[0...-2].to_f * -1
    end
  rescue
       nil
  end
end

def get_longitude(lat_long)
  puts "Getting longitude: #{lat_long}"
  begin
    longitude_s = lat_long.split(' / ')[1]
    if longitude_s.include? 'E'
      longitude_s[0...-2].to_f
    else
      longitude_s[0...-2].to_f * -1
    end
  rescue
    nil
  end
end

def get_rating(page)
  route_quality = nil
  star_check = page.css('li#current-rating')
  if star_check.count > 0
    puts 'Getting rating'
    stars = star_check[0]['style']
    route_quality = get_stars(stars)
  end

  route_quality
end

def get_stars(star_width)
  begin
    star_width.sub!('px;','')
    star_width.sub!('width:','')

    # The stars are filled with a div of width # stars # 13 px
    # Rating is on a scale of 0-5
    (star_width.to_f / 13) / MAX_STAR_RATING
  rescue
    nil
  end
end

def get_my_rating(page)
  my_route_quality = nil
  my_stars_check = page.css('span#meta_vote_reg')
  if my_stars_check.count > 0
    puts 'Getting my rating'
    my_stars = my_stars_check[0]
    my_stars = my_stars.split('voted ')[1]
    my_stars = my_stars.split(' stars')[0].strip
    my_route_quality = my_stars.to_f / MAX_STAR_RATING
  end

  my_route_quality
end

def get_elevation(page)
  begin
    elevation = get_main_data_box_item(page, 'Elevation: ')
    puts 'Getting elevation'
    elevation.split(' ft / ')[0]
  rescue
    nil
  end
end

def get_main_data_box_item(page, key)
  entries = page.css('div#main_data_box tr > td > p')

  value = nil
  entries.each { |entry|
    value = entry.text
    if value.start_with? key
      value.sub!(key, '').strip!
      break
    else
      value = nil
    end
  }
  value
end
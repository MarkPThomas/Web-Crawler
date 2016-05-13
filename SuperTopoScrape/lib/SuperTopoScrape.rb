require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https'
require 'net/http'
require 'fileutils'
require 'restclient'
require_relative 'Profile'

# See: http://ruby.bastardsbook.com/chapters/html-parsing/
# See: http://ruby.bastardsbook.com/chapters/web-crawling/

DATA_DIR = "data-hold/superTopo"
FileUtils::mkdir_p(DATA_DIR) unless File.exists?(DATA_DIR)

# Works
#BASE_URL = "http://www.supertopo.com/"
#LIST_URL = "#{BASE_URL}/tr/Bear-Creek-Spire-E-Ridge-An-Overlooked-Sierra-Classic/t12258n.html" # Works

#page = Nokogiri::HTML(open(LIST_URL,  :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
#rows = page.css('table.objectList tr')

# Below has been failing, as you need to be signed in in order to view the pages.

# post_signin.php
REQUEST_URL = "http://www.supertopo.com/inc/view_tripreports.php?dcid=Pj44PTU-OSI,"

# uses post_signin.php
# See inpect page> network, recording while signing in to get the submitted post recorded
# Loads the "Your Trip Reports" tab. Other postgotopage codes load other tabs
post_goto_page = 'A0RATB9HW1ZDakJFUUlIXkxSTEszbzIrNHoiJCEtdxsmeXofBAR_HAcceg,,'
email_term = USERNAME
password_term = PASSWORD

redirected_url = nil
result = RestClient.get(REQUEST_URL, {'postgotopage'=>post_goto_page,
                                      'email'=>email_term,
                                      'passwd'=>password_term,
                                      'Submit'=>'Sign+In'}){ |response, request, result, &block|
  if [301, 302, 307].include? response.code
    response.follow_redirection(request, result, &block)
  else
    redirected_url = request.url
    response.return!(request, result, &block)
  end
}

npage = Nokogiri::HTML(redirected_url)

npage = Nokogiri::HTML(REQUEST_URL)

titles = npage.css('h1')

RestClient.post(REQUEST_URL, {'postgotopage'=>post_goto_page,
                              'email'=>email_term,
                              'passwd'=>password_term,
                              'Submit'=>'Sign+In'}) do |response, request, result, &block|
  if [301, 302, 307].include? response.code
    redirected_url = response.headers[:location]
  else
    response.return!(request, result, &block)
  end
end

npage = Nokogiri::HTML(redirected_url)

titles = npage.css('h1')


if pagePost = RestClient.post(REQUEST_URL, {'postgotopage'=>post_goto_page,
                                            'email'=>email_term,
                                            'passwd'=>password_term,
                                            'Submit'=>'Sign+In'})
  npage = Nokogiri::HTML(pagePost)

  titles = npage.css('h1')

end


# LIST_URL = "#{BASE_URL}/inc/view_tripreports.php?dcid=Pj44PTU-OSI,"
# LIST_URL = "#{BASE_URL}/inc/signin.php?postgotopage=A0RATB9HW1ZDakJFUUlIXkxSTEszbzIrNHoiJCEtdxsmeXofBAR_HAcceg,,"
#LIST_URL = "#{BASE_URL}"  #/inc/signin.php"

# This is the URL for the POST request:
CGI_URL = 'http://query.nictusa.com/cgi-bin/fecgifpdf/'

# base_url + f_id = the URL for the form page with the button
base_url = 'http://www.supertopo.com/inc/post_signin.php?'
#f_id = 'postgotopage=P3h8cDtmf3B2cHQ1bHVu'
f_id = 'dcid=Pj44PTU-OSI,'

## 1 & 2: Retrieve the page with PDF generate button
form_page = Nokogiri::HTML(RestClient.get(base_url + f_id))
button = form_page.css('input[type="hidden"]')[0]



if pagePost = RestClient.post(REQUEST_URL, {button['name']=>button['value'], 'submit'=>'Sign+In'})
  npage = Nokogiri::HTML(pagePost)

  titles = npage.css('h1')

end



button = form_page.css('input[name="Submit" type="submit"]')[0]



#HEADERS_HASH = {"User-Agent" => "Ruby/#{RUBY_VERSION}"}

page = Nokogiri::HTML(open(LIST_URL))
rows = page.css('table.objectList tr')

rows[1..-2].each do |row|

  hrefs = row.css("td a").map{ |a|
    a['href'] if a['href'] =~ /^\/v\//
  }.compact.uniq

  hrefs.each do |href|
    remote_url = BASE_URL + href
    local_fname = "#{DATA_DIR}/#{File.basename(href)}.html"
    unless File.exists?(local_fname)
      puts "Fetching #{remote_url}..."
      begin
        #wiki_content = open(remote_url, HEADERS_HASH).read
        page_content = open(remote_url,  :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE).read
      rescue Exception=>e
        puts "Error: #{e}"
        sleep 5
      else
        File.open(local_fname, 'w'){|file| file.write(page_content)}
        puts "\t...Success, saved to #{local_fname}"
      ensure
        sleep 1.0 + rand
      end  # done: begin/rescue
    end # done: unless File.exists?

  end # done: hrefs.each
end # done: rows.each
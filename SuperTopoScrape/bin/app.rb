require_relative '../lib/SuperTopoScrape'
require_relative '../lib/Profile'

DATA_DIR = 'data-hold/superTopo'
BASE_URL = 'http://www.supertopo.com'

scrape_all(BASE_URL, USERNAME, PASSWORD, DATA_DIR)
require_relative '../lib/SuperTopoScrape'
require_relative '../lib/Profile'

DATA_DIR = 'data-hold/superTopo'

results = search_route_reference('The Nose')
overwrite_sub_hashes(results, "#{DATA_DIR}/search_test.txt")

scrape_all(USERNAME, PASSWORD, DATA_DIR)
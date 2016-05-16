require_relative '../lib/SummitPostScrape'

DATA_DIR = 'data-hold/summitPost'

TEST_DIR = '/test-data'
test_data_dir = "#{DATA_DIR}#{TEST_DIR}"

BASE_URL = 'http://www.summitpost.org'
PROFILE_URL = '/users/pellucidwombat/12893'

run_tests(BASE_URL, PROFILE_URL, test_data_dir)
scrape_all(BASE_URL, PROFILE_URL, DATA_DIR)
require_relative '../lib/SummitPostScrape'
require_relative '../lib/Profile'

DATA_DIR = 'data-hold/summitPost'
TEST_DIR = '/test-data'
test_data_dir = "#{DATA_DIR}#{TEST_DIR}"

PROFILE_URL = '/users/pellucidwombat/12893'

submit_trip_report('trip_report', USERNAME, PASSWORD)

#run_tests(PROFILE_URL, test_data_dir)
#scrape_all(PROFILE_URL, DATA_DIR)
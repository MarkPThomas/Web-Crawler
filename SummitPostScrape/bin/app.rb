require_relative '../lib/SummitPostScrape'

DATA_DIR = 'data-hold/summitPost'
TEST_DIR = '/test-data'
test_data_dir = "#{DATA_DIR}#{TEST_DIR}"

PROFILE_URL = '/users/pellucidwombat/12893'

run_tests(PROFILE_URL, test_data_dir)
scrape_all(PROFILE_URL, DATA_DIR)
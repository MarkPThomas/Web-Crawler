require_relative '../lib/MtnProjScrape'

DATA_DIR = 'data-hold/mountainProject'
TEST_DIR = '/test-data'
test_data_dir = "#{DATA_DIR}#{TEST_DIR}"

PROFILE_URL = '/u/mark-p-thomas//106560803'

#run_tests(test_data_dir)
scrape_all(PROFILE_URL, DATA_DIR)

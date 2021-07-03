# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
LOG_DIR = "./logs"
REQUEST_DIR = "./logs/requests"
# * will be replaced with the current date at the initialization
LOG_FILE = "log_*.txt"
LOG_DATE_FORMAT = "yyyy-mm-dd_HH:MM"
REQUEST_FILE = "*.json"
REQUEST_DATE_FORMAT = "yyyy-mm-dd_HH:MM:SS"

# Log flags
SAVE_TO_STDOUT = true
SAVE_TO_FILE = true
SAVE_SCHEDULES_TO_FILE = true
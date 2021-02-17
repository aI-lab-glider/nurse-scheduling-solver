# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
const ITERATION_NUMBER = 3000
const INITIAL_MAX_TABU_SIZE = 150
const INC_TABU_SIZE_ITER = 0
const SCHEDULE_PATH = "schedules/schedule_2016_august_frontend.json"

const NO_IMPROVE_QUIT_ITERS = 1000

# reactive tabu search
const FULL_NBHD_ITERS = 30

const EXTENDED_NBHD_ITERS = 4

const EXTENDED_NBHD_LVL_2 = 20
const EXTENDED_NBHD_LVL_1 = 10

const WRKS_RANDOM_FACTOR = 0.2

# Minimal score to decrease nbhd size
const NBHD_OPT_PEN = 200
# Percentage of nhbd checked while penalty is higher than the threshold
const NBHD_OPT_SAMPLE_SIZE = 0.2

# Shuffle schedule if stuck in local optima
const MAX_NO_IMPROVS = 10
const NO_RANDOM_CHANGES = 250

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module constants

using JSON

const PROJECT_SRC = dirname(@__FILE__) |> dirname

const DEFAULT_SHIFTS = JSON.parsefile(joinpath(PROJECT_SRC, "defaults/shifts.json"))
const DEFAULT_CONFIG = JSON.parsefile(joinpath(PROJECT_SRC, "defaults/priorities.json"))

const REQ_CHLDN_PER_NRS_DAY = 3
const REQ_CHLDN_PER_NRS_NIGHT = 5

const LONG_BREAK_HOURS = 35

# under and overtime pen is equal to hours from <0, MAX_OVERTIME>
const MAX_OVERTIME = 10 # scaled by the number of weeks
const MAX_UNDERTIME = 0 # scaled by the number of weeks

const DAY_BEGIN = 6
const NIGHT_BEGIN = 22

const PERIOD_BEGIN = 7

# weekly worktime
const WORKTIME_BASE = 40

const DAY_HOURS_NO = 24
const WEEK_DAYS_NO = 7
const NUM_WORKING_DAYS = 5
const SUNDAY_NO = 0

const WORKTIME_DAILY = WORKTIME_BASE / NUM_WORKING_DAYS

end # constants

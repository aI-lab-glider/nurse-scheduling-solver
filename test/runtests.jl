# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
cd("../")

include("old_engine/NurseScheduling.jl")
include("../src/repair_schedule.jl")

using Test
using .NurseSchedules:
    Schedule,
    get_disallowed_sequences,
    get_next_day_distance,
    get_earliest_shift_begin,
    get_latest_shift_end,
    sum_segments,
    within

include("engine_tests.jl")
include("shifts.jl")
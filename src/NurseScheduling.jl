# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module NurseScheduling

export Schedule,
       Neighborhood,
       score,
       get_shift_options,
       get_penalties,
       get_shifts,
       get_max_nbhd_size,
       get_month_info,
       get_workers_info,
       update_shifts!,
       n_split_nbhd,
       perform_random_jumps!,
       get_shifts_distance,
       Shifts

using JSON
using SuperEnum

include("nursescheduling/constants.jl")
include("nursescheduling/shifts.jl")
include("nursescheduling/schedule.jl")
include("nursescheduling/validation.jl")
include("nursescheduling/scoring.jl")
include("nursescheduling/neighborhood.jl")

using .schedulevalidation
using .scoring
using .neighborhood

end # NurseScheduling

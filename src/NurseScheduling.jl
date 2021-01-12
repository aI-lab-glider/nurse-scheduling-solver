# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module NurseSchedules

export Schedule,
       Neighborhood,
       score,
       get_penalties,
       get_shifts,
       get_max_nbhd_size,
       get_month_info,
       get_workers_info,
       update_shifts!,
       n_split_nbhd,
       get_shifts_distance,
       Shifts

using JSON
using SuperEnum

include("constants.jl")
include("schedule.jl")
include("validation.jl")
include("scoring.jl")
include("neighborhood.jl")

using .ScheduleValidation
using .ScheduleScoring
using .NeighborhoodGen

end # NurseSchedules

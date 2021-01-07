module NurseSchedules

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

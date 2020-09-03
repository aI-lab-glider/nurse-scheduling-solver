module NurseSchedules

export Schedule,
       Neighborhood,
       score,
       get_shifts,
       get_max_nbhd_size,
       get_month_info,
       get_workers_info,
       update_shifts!

using JSON

include("constants.jl")
include("Schedule.jl")
include("validation.jl")
include("score.jl")
include("neighborhood.jl")

using .ScheduleValidation
using .ScheduleScore
using .Neighborhood_gen

end # NurseSchedules

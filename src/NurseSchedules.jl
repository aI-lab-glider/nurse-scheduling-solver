module NurseSchedules

export Schedule,
       score,
       get_shifts,
       get_nbhd,
       get_max_nbhd_size

using Printf, JSON

include("schedule/constants.jl")
include("schedule/Schedule.jl")
include("schedule/validation.jl")
include("schedule/schedule_score.jl")
include("schedule/neighborhood.jl")

using .ScheduleValidation
using .ScheduleScore
using .Neighborhood

end # NurseSchedules

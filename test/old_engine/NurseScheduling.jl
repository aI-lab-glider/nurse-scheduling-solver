module OldNurseSchedules

export get_errors


using JSON
using SuperEnum

include("constants.jl")
include("schedule.jl")
include("scoring.jl")

using .ScheduleScoring

function get_errors(schedule_data)
    nurse_schedule = Schedule(schedule_data)
    schedule_shifts = get_shifts(nurse_schedule)
    _, errors = score(schedule_shifts, nurse_schedule, return_errors = true)
    return errors
end

end # NurseSchedules

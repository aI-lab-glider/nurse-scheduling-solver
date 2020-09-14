include("../src/NursesScheduling.jl")
include("../src/Schedule.jl")
using .NurseSchedules

import Base.in

Shifts = Array{String,2}
BestResult = @NamedTuple{shifts::Shifts, score::Int}

function get_errors(schedule_data)
    nurse_schedule = Schedule(schedule_data)

    schedule_shifts = get_shifts(nurse_schedule)
    workers, shifts = schedule_shifts
    month_info = get_month_info(nurse_schedule)
    workers_info = get_workers_info(nurse_schedule)

    errors = score((workers, schedule_shifts), month_info, workers_info, true)
    errors
end
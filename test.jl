include("src/NursesScheduling.jl")

using .NurseSchedules
using Logging

import Base.show
import .NurseSchedules: MutationRecipe, Mutation

function show(io::IO, mr::MutationRecipe)
    println("( mutation = $(mr.type), day = $(mr.day), wrk_no = $(mr.wrk_no), op = $(mr.op))")
end

logger = ConsoleLogger(stderr, Logging.Debug)
global_logger(logger)

schedule = Schedule("schedules/schedule_2016_august_medium.json")

schedule_shifts = get_shifts(schedule)
month_info = get_month_info(schedule)
workers_info = get_workers_info(schedule)

println(get_max_nbhd_size(schedule))

penalty, _ = score(schedule_shifts, month_info, workers_info)

nbhd = Neighborhood(schedule_shifts[2])

show(length(nbhd))

for i in nbhd
    show(i)
end

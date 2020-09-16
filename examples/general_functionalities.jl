include("../src/NursesScheduling.jl")
using .NurseSchedules
using Logging

import Base.show
import .NurseSchedules: MutationRecipe, Mutation

function show(io::IO, mr::MutationRecipe)
    println("( mutation = $(mr.type), day = $(mr.day), wrk_no = $(mr.wrk_no), op = $(mr.op))")
end

logger = ConsoleLogger(stderr, Logging.Debug)
global_logger(logger)

schedule = Schedule("schedules/schedule_2016_example_medium.json")

schedule_shifts = get_shifts(schedule)
month_info = get_month_info(schedule)
workers_info = get_workers_info(schedule)

println(get_max_nbhd_size(schedule))

penalty = score(schedule_shifts, month_info, workers_info)

nbhd = Neighborhood(schedule_shifts[2])

show(length(nbhd))

wrks, shifts = schedule_shifts

show(shifts)

# x = 0
# for i in nbhd
#     #show(i)
#     global x += 1
#     println(i)
# end
# show(x)

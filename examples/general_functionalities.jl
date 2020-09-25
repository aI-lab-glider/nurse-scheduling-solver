include("../src/NursesScheduling.jl")
using .NurseSchedules
using Logging

import Base: show
import .NurseSchedules: MutationRecipe, Mutation

logger = ConsoleLogger(stderr, Logging.Debug)
# global_logger(logger)

schedule = Schedule("schedules/schedule_2016_example_medium.json")

schedule_shifts = get_shifts(schedule)
workers, shifts = schedule_shifts
month_info = get_month_info(schedule)
workers_info = get_workers_info(schedule)

println("Max neighborhood size: ", get_max_nbhd_size(schedule), "\n")

wrks, shifts = schedule_shifts
println("Shifts:\n", shifts)

penalty = score(schedule_shifts, month_info, workers_info)

frozen_days = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 7)]
nbhd = Neighborhood(shifts, frozen_days)

println("Original day: \n", shifts[:, 6], "\nAll mutations of the day 6:")
for i in nbhd
    println(i[:, 6])
end

println("Actual neighborhood size: ", length(nbhd))

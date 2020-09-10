include("../src/NursesScheduling.jl")
using .NurseSchedules
using Logging
using JSON

BestResult = @NamedTuple{shifts::Array{String,2}, score::Int}

logger = ConsoleLogger(stderr, Logging.Debug)

nurse_schedule = Schedule("schedules/schedule_2016_august_medium.json")

schedule_shifts = get_shifts(nurse_schedule)
workers, shifts = schedule_shifts
month_info = get_month_info(nurse_schedule)
workers_info = get_workers_info(nurse_schedule)

penalty = score(schedule_shifts, month_info, workers_info)
best_shifts = BestResult((shifts, penalty))

iter_best = best_shifts
no_improvement_iters = 0
ITERATION_NUM = 1000
MAX_NO_IMPROVS = 20

for i in 1:ITERATION_NUM
    nbhd = Neighborhood(iter_best.shifts)
    nghd_scores = map(shifts -> score((workers, shifts), month_info, workers_info), nbhd)
    iter_best_idx = findfirst(nghd_scores .== minimum(nghd_scores))
    global iter_best = BestResult((nbhd[iter_best_idx], nghd_scores[iter_best_idx]))

    no_improvement_iters += 1

    if best_shifts.score > iter_best.score
        println("Penalty changed in iter '$(i)': '$(best_shifts.score)' -> '$(iter_best.score)'")
        global no_improvement_iters = 0
        global best_shifts = iter_best
    end
    if no_improvement_iters > MAX_NO_IMPROVS
        println("Local minimum! Stopping in iteration '$(i)'")
        break
    end
end

with_logger(logger) do
    penalty, logg = score((workers, best_shifts.shifts), month_info, workers_info, true)
    JSON.print(logg, 4)
end


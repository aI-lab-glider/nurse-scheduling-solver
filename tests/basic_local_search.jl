include("../src/NursesScheduling.jl")
using .NurseSchedules
using Logging

logger = ConsoleLogger(stderr, Logging.Debug)

nurse_schedule = Schedule("schedules/schedule_2016_august_medium.json")

schedule_shifts = get_shifts(nurse_schedule)
workers, shifts = schedule_shifts
month_info = get_month_info(nurse_schedule)
workers_info = get_workers_info(nurse_schedule)

penalty = score(schedule_shifts, month_info, workers_info)
best_shifts = (shifts, penalty)

iter_best = best_shifts
no_improvement_iters = 0
ITERATION_NUM = 1000

for i in 1:ITERATION_NUM
    nbhd = Neighborhood(iter_best[1])
    nghd_scores = map(shifts -> score((workers, shifts), month_info, workers_info), nbhd)
    iter_best_idx = findfirst(nghd_scores .== minimum(nghd_scores))
    global iter_best = (nbhd[iter_best_idx], nghd_scores[iter_best_idx])

    no_improvement_iters += 1

    if best_shifts[2] > iter_best[2]
        println("Improved from $(best_shifts[2]) to $(iter_best[2]) in iteration '$(i)'")
        global no_improvement_iters = 0
        global best_shifts = iter_best
    end
    if no_improvement_iters > 20
        println("Local minimum! Stopping in iteration '$(i)'")
        break
    end
end

with_logger(logger) do
    penalty, _ = score((workers, best_shifts[1]), month_info, workers_info, true)
end

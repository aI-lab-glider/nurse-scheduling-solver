include("../src/NursesScheduling.jl")
include("parameters.jl")
using .NurseSchedules
using Logging
using Base.Threads: @spawn, fetch

BestResult = @NamedTuple{shifts::Array{String,2}, score::Int}

logger = ConsoleLogger(stderr, Logging.Debug)

nurse_schedule = Schedule(SCHEDULE_PATH)

schedule_shifts = get_shifts(nurse_schedule)
workers, shifts = schedule_shifts
month_info = get_month_info(nurse_schedule)
workers_info = get_workers_info(nurse_schedule)

penalty = score(schedule_shifts, month_info, workers_info)
best_shifts = BestResult((shifts, penalty))

iter_best = best_shifts
no_improvement_iters = 0

for i = 1:ITERATION_NUMBER
    nbhd = Neighborhood(iter_best.shifts)
    nghd_scores = map(fetch, map(shifts -> @spawn(score((workers, shifts), month_info, workers_info)), nbhd))
    iter_best_idx = findfirst(nghd_scores .== minimum(nghd_scores))
    global iter_best = BestResult((nbhd[iter_best_idx], nghd_scores[iter_best_idx]))

    no_improvement_iters += 1

    println("[Iteration '$(i)']")
    if best_shifts.score > iter_best.score
        println("Penalty: '$(best_shifts.score)' -> '$(iter_best.score)' ($(iter_best.score - best_shifts.score))")
        global no_improvement_iters = 0
        global best_shifts = iter_best
    end
    if no_improvement_iters > MAX_NO_IMPROVS
        println("Local minimum! Stopping in iteration '$(i)'")
        break
    end
end

with_logger(logger) do
    improved_penalty, errors =
        score((workers, best_res.shifts), month_info, workers_info, true)
    println("Penaly improved: '$(penalty)' -> '$(improved_penalty)'")
end

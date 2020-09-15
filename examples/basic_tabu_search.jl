include("../src/NursesScheduling.jl")
using .NurseSchedules
using .NurseSchedules: Shifts
using Logging
using JSON

import Base.in

logger = ConsoleLogger(stderr, Logging.Debug)

BestResult = @NamedTuple{shifts::Shifts, score::Number}

ITERATION_NUMBER = 200
INITIAL_MAX_TABU_SIZE = 100
TABU_SIZE_INCREASE = 20
SCHEDULE_PATH = "schedules/schedule_2016_august_unsolvable.json"

function in(shifts::Shifts, tabu_list::Vector{BestResult})
    findfirst(record -> record.shifts == shifts, tabu_list) != nothing
end

nurse_schedule = Schedule(SCHEDULE_PATH)

schedule_shifts = get_shifts(nurse_schedule)
workers, shifts = schedule_shifts
month_info = get_month_info(nurse_schedule)
workers_info = get_workers_info(nurse_schedule)

penalty = score(schedule_shifts, month_info, workers_info)
best_res = BestResult((shifts = shifts, score = penalty))
best_iter_res = BestResult((shifts = best_res.shifts, score = Inf))

tabu_list = Vector{BestResult}()
push!(tabu_list, best_res)
max_tabu_size = INITIAL_MAX_TABU_SIZE

for i in 1:ITERATION_NUMBER
    result_improved = false

    global best_iter_res = BestResult((shifts = best_iter_res.shifts, score = Inf))

    nbhd = Neighborhood(best_iter_res.shifts)
    for candidate_shifts in nbhd
        candidate_score = score((workers, candidate_shifts), month_info, workers_info)
        if best_iter_res.score > candidate_score && !(candidate_shifts in tabu_list)
            global best_iter_res = BestResult((candidate_shifts, candidate_score))
        end
        if best_res.score > best_iter_res.score
            println("Penalty reduced in iter '$(i)': '$(best_res.score)' -> '$(best_iter_res.score)'")
            global best_res = best_iter_res
            result_improved = true
        end
        push!(tabu_list, best_iter_res)
        while length(tabu_list) > max_tabu_size
            popfirst!(tabu_list)
        end
    end

    if result_improved
        global max_tabu_size = INITIAL_MAX_TABU_SIZE
    else
        global max_tabu_size += TABU_SIZE_INCREASE
        println("Increasing max tabu size to: $(max_tabu_size)")
    end

    if best_res.score == 0 || length(tabu_list) > length(nbhd)
        println("We will not be better, finishing.")
        break
    end
    println("Best iter score: $(best_iter_res.score)")
end

with_logger(logger) do
    improved_penalty, errors = score((workers, best_res.shifts), month_info, workers_info, true)
    println("Penaly improved: '$(penalty)' -> '$(improved_penalty)'")
end

include("../src/NursesScheduling.jl")
using .NurseSchedules
using Logging
using JSON

import Base.in

Shifts = Array{String,2}
BestResult = @NamedTuple{shifts::Shifts, score::Int}

ITERATION_NUMBER = 50
TABU_MAX_SIZE = 10
SCHEDULE_PATH = "schedules/schedule_2016_august_medium.json"

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
best_iter_res = best_res
tabu_list = Vector{BestResult}()
push!(tabu_list, best_iter_res)

for i in 1:ITERATION_NUMBER
    nbhd = Neighborhood(best_iter_res.shifts)
    for nbr_shifts in nbhd
        candidate_score = score((workers, nbr_shifts), month_info, workers_info)
        if best_iter_res.score > candidate_score && !(nbr_shifts in tabu_list)
            global best_iter_res = BestResult((nbr_shifts, candidate_score))
        end
        if best_res.score > best_iter_res.score
            println("Penalty reduced in iter '$(i)': '$(best_res.score)' -> '$(best_iter_res.score)'")
            global best_res = best_iter_res
            if best_res.score == 0
                break
            end
        end
        push!(tabu_list, best_iter_res)
        if length(tabu_list) > TABU_MAX_SIZE
            popfirst!(tabu_list)
        end
    end
    if best_res.score == 0
        break
    end
end

improved_penalty, errors = score((workers, best_res.shifts), month_info, workers_info, true)
println("Errors:")
JSON.print(errors, 4)
println("Penaly improved: '$(penalty)' -> '$(improved_penalty)'")

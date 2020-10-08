include("../src/NursesScheduling.jl")
include("parameters.jl")
using .NurseSchedules
using .NurseSchedules: Shifts
using Logging
using StatsBase: sample
using DataStructures: OrderedDict

import Base.in
using Base.Threads: @spawn, fetch, nthreads

logger = ConsoleLogger(stderr, Logging.Debug)

BestResult = @NamedTuple{shifts::Shifts, score::Number}

function in(shifts::Shifts, tabu_list::OrderedDict{UInt,Shifts})
    haskey(tabu_list, hash(shifts))
end

function popfirst!(dict::OrderedDict)
    (key, _), _ = iterate(dict)
    delete!(dict, key)
end

function eval_frozen_shifts(
    month_info,
    errors::Vector,
    no_improved_iters::Int,
    workers,
)::Vector{Tuple{Int,Int}}
    num_days = length(month_info["children_number"])
    num_wrks = length(workers)

    always_frozen_shifts = [
        wrk === 0 ? (wrk, day_no) : (findfirst(w -> w === wrk, workers), day_no)
        for (wrk, day_no) in month_info["frozen_shifts"]
    ]

    exclusion_range = if no_improved_iters > FULL_NBHD_ITERS
        return always_frozen_shifts
    elseif no_improved_iters >= EXTENDED_NBHD_LVL_2
        2
    elseif no_improved_iters >= EXTENDED_NBHD_LVL_1
        1
    else
        0
    end

    day_errors = filter(error -> haskey(error, "day"), errors)
    iter_frozen_shifts = if !isempty(day_errors)
        changeable_days = Vector{Int}()
        for error in day_errors
            push!(changeable_days, error["day"])
            exclusion_range > 0 && push!(changeable_days, error["day"] - 1)
            exclusion_range > 1 && push!(changeable_days, error["day"] + 1)
        end

        println("Days being improved: $(length(Set(changeable_days)))")
        [(0, day_no) for day_no in setdiff(Set(1:num_days), Set(changeable_days))]
    else
        worker_errors = filter(error -> !haskey(error, "day"), errors)

        changeable_wrks = [
            findfirst(wrk_id -> wrk_id == error["worker"], workers)
            for error in worker_errors
        ]
        no_improved_iters > 0 && append!(
            changeable_wrks,
            sample(1:num_wrks, floor(Int, num_wrks * WRKS_RANDOM_FACTOR), replace = false),
        )
        println("Workers being improved: $(length(Set(changeable_wrks)))")
        [(wrk_no, 0) for wrk_no in setdiff(Set(1:num_wrks), Set(changeable_wrks))]
    end

    vcat(always_frozen_shifts, iter_frozen_shifts)
end

function get_best_nbr(nbhd::Neighborhood)::BestResult
    best_iter_res = BestResult((shifts = nbhd[1], score = Inf))
    for candidate_shifts in nbhd
        candidate_score = score((workers, candidate_shifts), month_info, workers_info)
        if best_iter_res.score > candidate_score && !(candidate_shifts in tabu_list)
                best_iter_res = BestResult((candidate_shifts, candidate_score))
        end
    end
    return best_iter_res
end

nurse_schedule = Schedule(SCHEDULE_PATH)

schedule_shifts = get_shifts(nurse_schedule)
workers, shifts = schedule_shifts
month_info = get_month_info(nurse_schedule)
workers_info = get_workers_info(nurse_schedule)

penalty = score(schedule_shifts, month_info, workers_info)
best_res = BestResult((shifts = shifts, score = penalty))
best_iter_res = BestResult((shifts = best_res.shifts, score = Inf))

tabu_list = OrderedDict{UInt64,Shifts}()
tabu_list[hash(best_res.shifts)] = best_res.shifts
max_tabu_size = INITIAL_MAX_TABU_SIZE
no_improved_iters = 0

for i = 1:ITERATION_NUMBER
    previous_best_iter_score = best_iter_res.score
    global best_iter_res = BestResult((shifts = best_iter_res.shifts, score = Inf))

    _, errors = score((workers, best_iter_res.shifts), month_info, workers_info, true)
    println("[Iteration '$(i)']")
    act_frozen_shifts = eval_frozen_shifts(month_info, errors, no_improved_iters, workers)
    nbhd = Neighborhood(best_iter_res.shifts, act_frozen_shifts)

    nbhds = n_split_nbhd(nbhd, nthreads())
    p_best_results = map(fetch, map(nbhd -> @spawn(get_best_nbr(nbhd)), nbhds))
    best_score = min([res.score for res in p_best_results]...)

    global best_iter_res = p_best_results[findfirst(res -> res.score == best_score, p_best_results)]

    if best_res.score > best_iter_res.score
        best_diff = " ($(best_iter_res.score - best_res.score))"
        global best_res = best_iter_res
        global no_improved_iters = 0
    else
        best_diff = ""
        global no_improved_iters += 1
    end
    println("The best score: '$(best_res.score)' $(best_diff)")

    if no_improved_iters < INC_TABU_SIZE_ITER
        global max_tabu_size = INITIAL_MAX_TABU_SIZE
        length(tabu_list) > INITIAL_MAX_TABU_SIZE &&
            println("Reseting max tabu size to: $(max_tabu_size)")
    elseif length(tabu_list) >= max_tabu_size
        global max_tabu_size += 1
        println("Incrementing max tabu size to: $(max_tabu_size)")
    end

    tabu_list[hash(best_iter_res.shifts)] = best_iter_res.shifts

    while length(tabu_list) > max_tabu_size
        popfirst!(tabu_list)
    end

    if length(unique(keys(tabu_list))) != length(unique(values(tabu_list)))
        println("Tabu list corrupted, holy crap!")
        exit(1)
    end

    if best_res.score == 0 || no_improved_iters > NO_IMPROVE_QUIT_ITERS
        println("We will not be better, finishing.")
        break
    else
        print("Iteration best score: $(best_iter_res.score)")
        scores_diff = best_iter_res.score - previous_best_iter_score
        if scores_diff == 0
            println(" (=0)")
        elseif scores_diff < 0
            println(" ($(scores_diff))")
        else
            println(" (+$(scores_diff))")
        end

    end
end

with_logger(logger) do
    improved_penalty, errors =
        score((workers, best_res.shifts), month_info, workers_info, true)
    println("Penaly improved: '$(penalty)' -> '$(improved_penalty)'")
    show(best_res.shifts)
end
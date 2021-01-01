include("NurseScheduling.jl")
include("parameters.jl")

using .NurseSchedules
using Logging
using Printf
using StatsBase: sample
using DataStructures: OrderedSet

import Base.in
using Base.Threads: @spawn, fetch, nthreads

BestResult = @NamedTuple{shifts::Union{Shifts,Nothing}, score::Number}
logger = ConsoleLogger(stderr, Logging.Debug)


function get_errors(schedule_data)

    nurse_schedule = Schedule(schedule_data)

    schedule_shifts = get_shifts(nurse_schedule)
    month_info = get_month_info(nurse_schedule)
    workers_info = get_workers_info(nurse_schedule)
    schedule_penalties = get_penalties(nurse_schedule)

    _, errors = score(schedule_shifts, nurse_schedule, return_errors = true)
    return errors
end

function repair_schedule(schedule_data)

    nurse_schedule = Schedule(schedule_data)

    schedule_shifts = get_shifts(nurse_schedule)
    workers, shifts = schedule_shifts
    month_info = get_month_info(nurse_schedule)

    initial_penalty = score(schedule_shifts, nurse_schedule)
    best_res = BestResult((shifts = shifts, score = initial_penalty))
    best_iter_res = BestResult((shifts = best_res.shifts, score = Inf))

    max_tabu_size = INITIAL_MAX_TABU_SIZE
    tabu_list = OrderedSet{UInt64}()
    push!(tabu_list, hash(best_res.shifts))

    no_improved_iters = 0

    for i = 1:ITERATION_NUMBER
        println("[Iteration $(i)]")

        previous_best_iter_score = best_iter_res.score
        best_iter_res = BestResult((shifts = best_iter_res.shifts, score = Inf))

        _, errors = score(
            (workers, best_iter_res.shifts),
            nurse_schedule,
            return_errors = true
        )
        act_frozen_shifts = eval_frozen_shifts(month_info, errors, no_improved_iters, workers, !(previous_best_iter_score > NBHD_OPT_PEN))
        nbhd = if previous_best_iter_score > NBHD_OPT_PEN
            Neighborhood(best_iter_res.shifts, act_frozen_shifts, NBHD_OPT_SAMPLE_SIZE)
        else
            Neighborhood(best_iter_res.shifts, act_frozen_shifts)
        end

        if length(nbhd) == 0
            println("Nbhd empty after the frozen shifts evaluation")
            nbhd = Neighborhood(best_iter_res.shifts)
        end

        nbhds = n_split_nbhd(nbhd, nthreads())
        p_best_results = map(
            fetch,
            map(
                nbhd -> @spawn(get_best_nbr(
                    nbhd,
                    nurse_schedule,
                    tabu_list,
                    (workers, shifts)
                )),
                nbhds,
            ),
        )

        _, best_score_pos = findmin([res.score for res in p_best_results])
        best_iter_res = p_best_results[best_score_pos]

        if best_res.score > best_iter_res.score
            best_diff = @sprintf "(%.2f)" best_iter_res.score - best_res.score
            best_res = best_iter_res
            no_improved_iters = 0
        else
            best_diff = ""
            no_improved_iters += 1
        end
        println(@sprintf "The best score: '%.3f' %s" best_res.score best_diff)

        if no_improved_iters <= INC_TABU_SIZE_ITER
            max_tabu_size = INITIAL_MAX_TABU_SIZE
            length(tabu_list) > INITIAL_MAX_TABU_SIZE &&
                println("Reseting max tabu size to: $(max_tabu_size)")
        elseif length(tabu_list) >= max_tabu_size
            max_tabu_size += 1
            println("Increasing max tabu size to: $(max_tabu_size)")
        end

        push!(tabu_list, hash(best_iter_res.shifts))

        while length(tabu_list) > max_tabu_size
            popfirst!(tabu_list)
        end

        if best_res.score < 1 || no_improved_iters > NO_IMPROVE_QUIT_ITERS
            println("We will not be better, finishing.")
            break
        else
            print(@sprintf "Iteration best score: '%.3f'" best_iter_res.score)
            scores_diff = previous_best_iter_score == Inf ? 0 :
                best_iter_res.score - previous_best_iter_score
            if scores_diff == 0
                println(" (=)")
            elseif scores_diff < 0
                println(@sprintf " (%.2f)" scores_diff)
            else
                println(@sprintf " (+%.2f)" scores_diff)
            end
        end
    end

    with_logger(logger) do
        improved_penalty, errors = score(
            (workers, best_res.shifts),
            nurse_schedule,
            return_errors = true,
        )
        println("Penalty changed: '$(initial_penalty)' -> '$(improved_penalty)'")
        println("Number of changes with respect to initial shifts: '$(get_shifts_distance(shifts, best_res.shifts))'")
        show(best_res.shifts)
    end

    return best_res.shifts
end

function popfirst!(set::OrderedSet)
    value, _ = iterate(set)
    delete!(set, value)
end

function eval_frozen_shifts(
    month_info,
    errors::Vector,
    no_improved_iters::Int,
    workers,
    return_iter_shifts::Bool
)::Vector{Tuple{Int,Int}}
    num_days = length(month_info["children_number"])
    num_wrks = length(workers)

    always_frozen_shifts = [
        (wrk === 0 ? wrk : findfirst(w -> w === wrk, workers), day_no)
        for (wrk, day_no) in month_info["frozen_shifts"]
    ]

    if !return_iter_shifts
        return always_frozen_shifts
    end

    exclusion_range = if no_improved_iters > FULL_NBHD_ITERS
        println("Entire nbhd being evaluated")
        return always_frozen_shifts
    elseif no_improved_iters > EXTENDED_NBHD_LVL_2
        2
    elseif no_improved_iters > EXTENDED_NBHD_LVL_1
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

        println("Number of days being evaluated: '$(length(Set(changeable_days)))'")
        [(0, day_no) for day_no in setdiff(Set(1:num_days), Set(changeable_days))]
    else
        changeable_wrkrs = [
            findfirst(wrk_id -> wrk_id == error["worker"], workers) for error in errors
        ]
        no_improved_iters > 0 && append!(
            changeable_wrkrs,
            sample(1:num_wrks, floor(Int, num_wrks * WRKS_RANDOM_FACTOR), replace = false),
        )
        println("Number of workers being evaluated: '$(length(Set(changeable_wrkrs)))'")
        [(wrk_no, 0) for wrk_no in setdiff(Set(1:num_wrks), Set(changeable_wrkrs))]
    end
    return vcat(always_frozen_shifts, iter_frozen_shifts)
end

function get_best_nbr(nbhd::Neighborhood, schedule::Schedule, tabu_list, schedule_shifts)::BestResult
    best_ngb = BestResult((shifts = nothing, score = Inf))
    workers, initial_shifts = schedule_shifts

    length(nbhd) == 0 && return best_ngb

    for candidate_shifts in nbhd
        candidate_shifts in tabu_list && continue
        candidate_score = score((workers, candidate_shifts), schedule)
        candidate_score += get_shifts_distance(initial_shifts, candidate_shifts) / length(initial_shifts)
        if best_ngb.score > candidate_score
            best_ngb = BestResult((candidate_shifts, candidate_score))
        end
    end
    return best_ngb
end

in(shifts::Shifts, tabu_list::OrderedSet{UInt}) = hash(shifts) in tabu_list

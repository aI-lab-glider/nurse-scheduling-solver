import Base.in

BestResult = @NamedTuple{shifts::Shifts, score::Number}

function repair_schedule(schedule_data)
    ITERATION_NUMBER = 20
    INITIAL_MAX_TABU_SIZE = 20
    INC_TABU_SIZE_ITER = 5

    function in(shifts::Shifts, tabu_list::Vector{BestResult})
        findfirst(record -> record.shifts == shifts, tabu_list) != nothing
    end

    global nurse_schedule = Schedule(schedule_data)

    global schedule_shifts = get_shifts(nurse_schedule)
    global workers, shifts = schedule_shifts
    global month_info = get_month_info(nurse_schedule)
    global workers_info = get_workers_info(nurse_schedule)

    global penalty = score(schedule_shifts, month_info, workers_info)
    global best_res = BestResult((shifts = shifts, score = penalty))
    global best_iter_res = BestResult((shifts = best_res.shifts, score = Inf))

    global tabu_list = Vector{BestResult}()
    push!(tabu_list, best_res)
    global max_tabu_size = INITIAL_MAX_TABU_SIZE
    global no_improved_iters = 0

    for i = 1:ITERATION_NUMBER
        best_iter_res = BestResult((shifts = best_iter_res.shifts, score = Inf))

        nbhd = Neighborhood(best_iter_res.shifts)
        for candidate_shifts in nbhd
            candidate_score = score((workers, candidate_shifts), month_info, workers_info)
            if best_iter_res.score > candidate_score && !(candidate_shifts in tabu_list)
                global best_iter_res = BestResult((candidate_shifts, candidate_score))
            end
        end

        if best_res.score > best_iter_res.score
            global best_res = best_iter_res
            global no_improved_iters = 0
        else
            global no_improved_iters += 1
        end

        push!(tabu_list, best_iter_res)

        while length(tabu_list) > max_tabu_size
            popfirst!(tabu_list)
        end

        if no_improved_iters < INC_TABU_SIZE_ITER
            global max_tabu_size = INITIAL_MAX_TABU_SIZE
        elseif length(tabu_list) == max_tabu_size
            global max_tabu_size += 1
        end

        if best_res.score == 0
            break
        end
    end

    best_res.shifts
end
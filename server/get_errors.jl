import Base.in

BestResult = @NamedTuple{shifts::Shifts, score::Number}

function get_errors(schedule_data)
    function in(shifts::Shifts, tabu_list::Vector{BestResult})
        findfirst(record -> record.shifts == shifts, tabu_list) != nothing
    end

    global nurse_schedule = Schedule(schedule_data)

    global schedule_shifts = get_shifts(nurse_schedule)
    global month_info = get_month_info(nurse_schedule)
    global workers_info = get_workers_info(nurse_schedule)

    global _, errors = score(schedule_shifts, month_info, workers_info, true)
    errors
end
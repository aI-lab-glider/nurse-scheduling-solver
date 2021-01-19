using ..NurseSchedules:
        CONFIG,
        SHIFTS,
        get_distance,
        get_rest_length

mutable struct Schedule
    data::Dict

    function Schedule(filename::AbstractString)
        data = JSON.parsefile(filename)
        Schedule(data)
    end

    function Schedule(data::Dict{String,Any})
        validate(data)
        @debug "Schedule loaded correctly."
        new(data)
    end
end

function get_penalties(schedule)::Dict{String,Any}
    weights = CONFIG["weight_map"]
    custom_priority = get(schedule.data, "penalty_priorities", nothing)
    penalties = Dict{String,Any}()

    priority = if !isnothing(custom_priority)
        custom_priority
    else
        CONFIG["penalties"]
    end

    for (key, pen) in zip(priority, weights)
        penalties[key] = pen
    end
    return penalties
end

function get_shift_options(schedule::Schedule)
    if !("shift_types" in keys(schedule.data))
        SHIFTS
    else
        get(schedule.data, "shift_types", Dict())
    end
end

function get_day(schedule::Schedule)
    day_begin = get(schedule.data["month_info"], "day_begin", DAY_BEGIN)
    day_end   = get(schedule.data["month_info"], "night_begin", DAY_END)
    return (day_begin, day_end)
end

function get_changeable_shifts_keys(schedule::Schedule)
    [ key for (key, shift) in get_shift_options(schedule)
        if shift["is_working_shift"]
    ]
end

function get_disallowed_sequences(schedule::Schedule)
    shift_dict = get_shift_options(schedule)
    Dict(
        shift => [
            illegal_shift 
            for illegal_shift in get_changeable_shifts_keys(schedule)
            if get_distance(shift_dict[shift], shift_dict[illegal_shift]) <= get_rest_length(shift_dict[shift])
        ] for shift in get_changeable_shifts_keys(schedule) 
    )
end

function get_shifts(schedule::Schedule)::ScheduleShifts
    workers = collect(keys(schedule.data["shifts"]))
    shifts = collect(values(schedule.data["shifts"]))

    return workers,
    [shifts[person][shift] for person = 1:length(shifts), shift = 1:length(shifts[1])]
end

function get_month_info(schedule::Schedule)::Dict{String,Any}
    return schedule.data["month_info"]
end

function get_workers_info(schedule::Schedule)::Dict{String,Any}
    return schedule.data["employee_info"]
end

function update_shifts!(schedule::Schedule, shifts)
    workers, _ = get_shifts(schedule)
    for worker_no in axes(shifts, 1)
        schedule.data["shifts"][workers[worker_no]] = shifts[worker_no, :]
    end
end

get_shifts_distance(shifts_1::Shifts, shifts_2::Shifts)::Int =
    count(s -> s[1] != s[2], zip(shifts_1, shifts_2))


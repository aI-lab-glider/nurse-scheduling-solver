using ..NurseSchedules:
        CONFIG

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
    weights = CONFIG["weightMap"]
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


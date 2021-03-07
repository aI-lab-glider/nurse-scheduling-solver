# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
using ..NurseSchedules:
        CONFIG,
        SHIFTS,
        W_DICT,
        get_next_day_distance,
        get_rest_length        

mutable struct Schedule
    data::Dict

    function Schedule(filename::AbstractString)
        data = JSON.parsefile(filename)
        if haskey(data, "shift_types") && !haskey(data["shift_types"], "W")
            data["shift_types"]["W"] = W_DICT
        end
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
    default_priority = CONFIG["penalties"]
    custom_priority = get(schedule.data, "penalty_priorities", nothing)
    penalties = Dict{String,Any}()

    if isnothing(custom_priority)
        return Dict(
            key => pen
            for (key, pen) in zip(default_priority, weights)
        )
    end

    for key in default_priority
        if key in custom_priority
            penalties[key] = weights[findall(x -> x == key, custom_priority)[1]]
        else
            penalties[key] = 0
        end
    end

    return penalties
end

function get_shift_options(schedule::Schedule)
    if !("shift_types" in keys(schedule.data))
        SHIFTS 
    else
        schedule.data["shift_types"]
    end
end

function get_day(schedule::Schedule)
    day_begin = get(schedule.data["month_info"], "day_begin", DAY_BEGIN)
    day_end   = get(schedule.data["month_info"], "night_begin", NIGHT_BEGIN)
    return (day_begin, day_end)
end

function get_changeable_shifts(schedule::Schedule)
    filter(
        kv -> kv.second["is_working_shift"],
        get_shift_options(schedule)
    )
end

function get_exempted_shifts(schedule::Schedule)
    filter(
        kv -> !kv.second["is_working_shift"] && kv.first != "W",
        get_shift_options(schedule)
    )
end

function get_disallowed_sequences(schedule::Schedule)
    Dict(
        first_shift_key => [
            second_shift_key 
            for (second_shift_key, second_shift_val) in get_changeable_shifts(schedule)
            if get_next_day_distance(first_shift_val, second_shift_val) <= get_rest_length(first_shift_val)
        ] for (first_shift_key, first_shift_val) in get_changeable_shifts(schedule) 
    )
end


function get_earliest_shift_begin(schedule::Schedule)
    changeable_shifts = collect(values(get_changeable_shifts(schedule))) 
    minimum(x -> x["from"],
            changeable_shifts     
    )
end

function get_latest_shift_end(schedule::Schedule)
    changeable_shifts = collect(values(get_changeable_shifts(schedule)))
    maximum(x -> x["to"] > x["from"] ? x["to"] : 24 + x["to"],
            changeable_shifts
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


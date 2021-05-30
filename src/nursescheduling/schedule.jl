# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module schedule

export Schedule,
    penalties,
    workers_info,
    month_info,
    shift_options,
    disallowed_sequences,
    changeable_shifts,
    exempted_shifts,
    earliest_shift_begin,
    latest_shift_end,
    day

struct Schedule
    employees::Vector{String}
    shifts::Array{UInt8}
    metadata::Dict
    shift_map::Dict{String,UInt8}
    reverse_map::Dict{UInt8,String}
end

# constructors
function Schedule(filename::String)
    data = JSON.parsefile(filename)
    Schedule(data)
end

function Schedule(data::Dict{String,Any})
    # validate(data)

    shift_types = "shift_types" in keys(data) ? data["shift_types"] : SHIFTS
    shift_map, reverse_map = _map_shift_codes(keys(shift_types))

    new(data, shift_map, reverse_map)
end

function _map_shift_codes(shift_codes)
    shift_map = Dict{String,UInt8}()
    reverse_map = Dict{UInt8,String}()
    reverse_map[W_ID] = W
    shift_map[W] = W_ID
    next_val = W_ID + 1

    for key in shift_codes
        if key != W
            shift_map[key] = next_val
            reverse_map[next_val] = key
            next_val += 1
        end
    end

    shift_map, reverse_map
end

# schedule getters

function month_info(schedule::Schedule)::Dict{String,Any}
    return schedule.data["month_info"]
end

function employee_info(schedule::Schedule)::Dict{String,Any}
    return schedule.data["employee_info"]
end

function raw_options(schedule::Schedule)
    return "shift_types" in keys(schedule.data) ? schedule.data["shift_types"] : SHIFTS
end

function shift_options(schedule::Schedule)
    base = raw_options(schedule)
    return Dict(schedule.shift_map[k] => v for (k, v) in base)
end

function penalties(schedule::Schedule)::Dict{String,Any}
    weights = CONFIG["weight_map"]
    default_priority = CONFIG["penalties"]
    custom_priority = get(schedule.data, "penalty_priorities", nothing)
    penalties = Dict{String,Any}()

    if isnothing(custom_priority)
        return Dict(key => pen for (key, pen) in zip(default_priority, weights))
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

function day(schedule::Schedule)
    day_begin = get(schedule.data["month_info"], "day_begin", DAY_BEGIN)
    day_end = get(schedule.data["month_info"], "night_begin", NIGHT_BEGIN)
    return (day_begin, day_end)
end

function changeable_shifts(schedule::Schedule)
    filter(kv -> kv.second["is_working_shift"], shift_options(schedule))
end

function exempted_shifts(schedule::Schedule)
    filter(
        kv -> !kv.second["is_working_shift"] && kv.first != W_ID,
        get_shift_options(schedule),
    )
end

function disallowed_sequences(schedule::Schedule)
    Dict(
        first_shift_key => [
            second_shift_key
            for
            (second_shift_key, second_shift_val) in get_changeable_shifts(schedule) if
            get_next_day_distance(first_shift_val, second_shift_val) <=
            get_rest_length(first_shift_val)
        ] for (first_shift_key, first_shift_val) in changeable_shifts(schedule)
    )
end

function earliest_shift_begin(schedule::Schedule)
    changeable_shifts = collect(values(changeable_shifts(schedule)))
    minimum(x -> x["from"], changeable_shifts)
end

function latest_shift_end(schedule::Schedule)
    changeable_shifts = collect(values(changeable_shifts(schedule)))
    maximum(x -> x["to"] > x["from"] ? x["to"] : 24 + x["to"], changeable_shifts)
end

function shifts(schedule::Schedule)::ScheduleShifts
    workers = collect(keys(schedule.data["shifts"]))
    shifts = collect(map(
        x -> map(y -> schedule.shift_map[y], x),
        values(schedule.data["shifts"]),
    ))

    return workers,
        [shifts[person][shift] for person = 1:length(shifts), shift = 1:length(shifts[1])],
end

function update_shifts!(schedule::Schedule, shifts::Shifts)
    workers, _ = shifts(schedule)
    for worker_no in axes(shifts, 1)
        schedule.data["shifts"][workers[worker_no]] =
            map(x -> schedule.reverse_map[x], shifts[worker_no, :])
    end
end

function get_period_range()::Vector{Int}
    vcat(collect(PERIOD_BEGIN:24), collect(1:(PERIOD_BEGIN - 1)))
end

function get_shifts_distance(shifts_1::Shifts, shifts_2::Shifts)::Int
    return count(s -> s[1] != s[2], zip(shifts_1, shifts_2))
end

end # schedule

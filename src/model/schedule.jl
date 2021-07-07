# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module schedule

export Schedule,
    Shifts,
    shifts,
    base_shifts,
    actual_shifts,
    decode_shifts,
    employee_uuid,
    employee_shifts,
    employee_base_shifts,
    employee_actual_shifts

using JSON

include("constants.jl")
include("types.jl")

using .constants: DEFAULT_SHIFTS
using .types: BasicShift

Shifts = Matrix{UInt8}

struct Schedule
    meta::Dict{String,Any}
    shift_coding::Dict{String,UInt8}

    function Schedule(schedule_json::Dict)
        available_shifts = get(schedule_json, "available_shifts", DEFAULT_SHIFTS)
        shift_coding = _make_shift_coding(available_shifts)

        new(schedule_json, shift_coding)
    end

    Schedule(filepath::String) = Schedule(JSON.parsefile(filepath))
end

function _make_shift_coding(available_shifts::Vector)::Dict{String,UInt8}
    shift_coding = Dict(
        string(instance) => UInt8(instance) for
        instance in instances(BasicShift.BasicShiftEnum)
    )

    for shift_info in available_shifts
        if !haskey(shift_coding, shift_info["code"])
            shift_coding[shift_info["code"]] = length(shift_coding)
        end
    end
    return shift_coding
end

# schedule getters
function shifts(schedule::Schedule, shifts_key::String)::Shifts
    shifts = [
        map(code -> schedule.shift_coding[code], e[shifts_key]) for
        e in schedule.meta["employees"]
    ]
    shifts = transpose(hcat(shifts...))
    return shifts
end

base_shifts(schedule::Schedule)::Shifts = shifts(schedule, "base_shifts")
actual_shifts(schedule::Schedule)::Shifts = shifts(schedule, "actual_shifts")

function decode_shifts(schedule::Schedule, shifts::Shifts)::Matrix{String}
    decoding = Dict(v => k for (k, v) in pairs(schedule.shift_coding))
    return map(coded_shift -> decoding[coded_shift], shifts)
end

employee_uuid(schedule::Schedule, idx::Int)::String =
    schedule.meta["employees"][idx]["uuid"]

employee_shifts(schedule::Schedule, idx::Int, shifts_key::String)::Vector{String} =
    schedule.meta["employees"][idx][shifts_key]

employee_actual_shifts(schedule::Schedule, idx::Int)::Vector{String} =
    employee_shifts(schedule, idx, "actual_shifts")

employee_base_shifts(schedule::Schedule, idx::Int)::Vector{String} =
    employee_shifts(schedule, idx, "base_shifts")

###########################################
#            ☠☠☠ WATCH OUT! ☠☠☠           #
# everything below is possibly deprecated #
###########################################

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

function daytime_range(schedule::Schedule)
    daytime_begin = get(schedule.meta["settings"], "daytime_begin", DAY_BEGIN)
    daytime_end = get(schedule.meta["settings"], "night_begin", NIGHT_BEGIN)
    return (daytime_begin, daytime_end)
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
            second_shift_key for
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

function get_period_range()::Vector{Int}
    vcat(collect(PERIOD_BEGIN:24), collect(1:(PERIOD_BEGIN - 1)))
end

function get_shifts_distance(shifts_1::Shifts, shifts_2::Shifts)::Int
    return count(s -> s[1] != s[2], zip(shifts_1, shifts_2))
end

end # schedule

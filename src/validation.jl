# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ScheduleValidation

using JSON

export validate

function validate(data::Dict)
    resp = contains_all_keys(data)
    if resp != "OK"
        error("Schedule input file is corrupted: $resp")
    end

    resp = same_lngth_shifts(data)
    if resp != "OK"
        error("Schedule input file is corrupted: $resp")
    end

    resp = contains_all_or_none_penalties(data)
    if resp != "OK"
        error("Schedule input file is corrupted: $resp")
    end
end

function contains_all_keys(data::Dict)
    REQUIRED_KEYS = ["month_info", "shifts"]
    for key in REQUIRED_KEYS
        if !(key in keys(data))
            return "a missing key '$key'"
        end
    end
    "OK"
end

function same_lngth_shifts(data::Dict)
    shifts = data["shifts"]
    first_val = length(collect(values(shifts))[1])
    for (key, value) in shifts
        if first_val != length(value)
            return "wrong shift length '$key'"
        end
    end
    "OK"
end

function contains_all_or_none_penalties(data::Dict)
    schedule_priority = get(data, "penalty_priorities", nothing)

    if !isnothing(schedule_priority)
        default_priority = JSON.parsefile("config/default.json")["penalties"]
        sort!(schedule_priority)
        sort!(default_priority)
        if length(default_priority) != length(schedule_priority)
            "wrong priorities length, received '$(length(schedule_priority))', excpected '$(length(default_priority))'"
        elseif !isequal(default_priority, schedule_priority)
            "priorities list doesn't contain all entries"
        else
            "OK"
        end
    else
        "OK"
    end
end

end # ScheduleValidation

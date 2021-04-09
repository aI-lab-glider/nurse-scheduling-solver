# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# Shift hours are half open interval
# [from, to)

ShiftType = Dict{String, Any}



"""
    Returns number of hours to be substracted from the norm
    Args:
        shift::ShiftType    - dictionary containing shift description
"""
function get_shift_norm_sub(shift::ShiftType)::Int
    if shift["is_working_shift"]
        0
    else
        get(shift, "normSubstraction", 8)
    end
end

"""
    Computes wheter an hour is inside the shift
    Args:
        hour::Int           - checked hour
        shift::ShiftType    - dictionary containing shift description
"""
function within(hour::Int, shift::ShiftType)::Bool
    if !shift["is_working_shift"]
        false
    elseif shift["from"] > shift["to"]
        !(shift["to"] <= hour < shift["from"])
    elseif shift["to"] > shift["from"]
        shift["from"] <= hour < shift["to"]
    else
        true
    end
end

"""
    Computes distance in hours between two consecutive shifts
    Args:
        first_shift::ShiftType  - dictionary containing shift description
        second_shift::ShiftType - dictionary of the next shift 
"""
function get_next_day_distance(first_shift::ShiftType, second_shift::ShiftType)::Int
    if first_shift["from"] < first_shift["to"]
        24 + second_shift["from"] - first_shift["to"]
    else
        second_shift["from"] - first_shift["to"]
    end
end

"""
    Computes minimal rest length in hours after the shift
    Args:
        shift::ShiftType    - dictionary containing shift description
"""
function get_rest_length(shift::ShiftType)::Int
    # 0-8h -> 11h rest
    # 9-12h -> 16h rest
    # 13-24h -> 24h rest
    len = get_shift_length(shift)
    if len <= 12
        11
    elseif len <= 16
        16
    else
        24
    end
end

# Assumption
# Always:
# DAY_BEGIN < DAY_END
# Thus night periods always crosses midnight, and day shift never

# Day is also a half open interval
# [DAY_BEGIN, DAY_END)

"""
    Computes shift length in hours
    Args:
        shift::ShiftType    - dictionary containing shift description
"""
function get_shift_length(shift::ShiftType)::Int
    if !shift["is_working_shift"]
        0
    else
        get_interval_length(shift["from"], shift["to"])
    end
end

"""
    Computes interval length between two hours. Assumes that, if interval is negative (ie. from > to)
    From-hour is in the next day.

    Args:
        from::Int   - beginning of the interval
        to::Int     - end of the interval
"""
function get_interval_length(from::Int, to::Int)::Int
    if from > to
        24 - from +  to
    elseif to > from
        to - from
    else
        24
    end
end

"""
    Computes total length of segments list in hours
    Args:
        segments  - list of segments
"""
function sum_segments(segments)::Int
    hours = 0
    for (start, stop) in segments
        hours += get_interval_length(start, stop)
    end
    return hours
end
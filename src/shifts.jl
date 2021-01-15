# Shift hours are half open interval
# [from, to)

function within(hour, shift)::Bool
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

function get_shifts_distance(first_shift, second_shift)
    if first_shift["from"] < first_shift["to"]
        24 + second_shift["from"] - first_shift["to"]
    else
        second_shift["from"] - first_shift["to"]
    end
end

function get_rest_length(shift)::Int
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

function get_shift_length(shift)::Int
    if !shift["is_working_shift"]
        0
    elseif shift["from"] > shift["to"]
        24 - shift["from"] +  shift["to"]
    elseif shift["to"] > shift["from"]
        shift["to"] - shift["from"]
    else
        24
    end
end
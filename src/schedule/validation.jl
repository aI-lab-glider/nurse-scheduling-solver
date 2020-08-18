module ScheduleValidation

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

end # ScheduleValidation

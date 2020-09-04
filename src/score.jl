module ScheduleScore

export score

using Statistics
using ..NurseSchedules


function score(schedule_shifts::ScheduleShifts, month_info::Dict{String,Any}, workers_info::Dict{String,Any})::Int
    workers, shifts = schedule_shifts
    penalty = 0
    # Strong constraints
    penalty += check_workers_presence(shifts, month_info)
    penalty += check_workers_rights(workers, shifts)
    if penalty > 0
        addtional_penalty = MAX_STD + length(workers) * MAX_OVER_TIME + 1
        @debug "Hard constraints are not met, charging additional penalty: '$(addtional_penalty)'"
        penalty += addtional_penalty
    else
        # Soft constraints, check only if hard are satisfied
        penalty += check_workers_overtime(workers, shifts, workers_info)
    end

    return penalty
end

function check_workers_presence(shifts, month_info)::Int
    penalty = 0
    for day in axes(shifts, 2)
        req_nrs_day::Int = ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_DAY)
        req_nrs_night::Int =
            ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_NIGHT)

        act_nrs_night = count(s -> (s in SHIFTS_NIGHT), shifts[:, day])

        act_nrs_day = count(s -> (s in SHIFTS_FULL_DAY), shifts[:, day])
        act_nrs_day += min(
            count(s -> (s == R), shifts[:, day]),
            count(s -> (s in [P, PN]), shifts[:, day]),
        )
        # night shifts complement day shifts
        act_nrs_day = (act_nrs_day > act_nrs_night) ? act_nrs_night : act_nrs_day

        missing_nrs_day = req_nrs_day - act_nrs_day
        missing_nrs_day = (missing_nrs_day < 0) ? 0 : missing_nrs_day
        missing_nrs_night = req_nrs_night - act_nrs_night
        missing_nrs_night = (missing_nrs_night < 0) ? 0 : missing_nrs_night

        day_pen = (missing_nrs_day + missing_nrs_night) * PEN_LACKING_NURSE
        penalty += day_pen

        if day_pen > 0
            error_details = ""
            if missing_nrs_day > 0
                error_details *= "\nExpected '$(req_nrs_day)', got '$(act_nrs_day)' in the day."
            end
            if missing_nrs_night > 0
                error_details *= "\nExpected '$(req_nrs_night)', got '$(act_nrs_night)' at night."
            end
            @debug "Lacking nurses on day '$day'." * error_details
        end
    end
    if penalty > 0
        @debug "Total lack of nurses penalty: $(penalty)"
    end
    return penalty
end

function check_workers_rights(workers, shifts)::Int
    penalty = 0
    for worker_no in axes(shifts, 1)
        long_breaks = fill(false, ceil(Int, size(shifts, 2) / length(DAYS_OF_WEEK)))

        for shift_no in axes(shifts, 2)
            # do not check right on the month last day
            if shift_no == size(shifts, 2)
                continue
            end

            if shifts[worker_no, shift_no] in keys(DISALLOWED_SHIFTS_SEQS) &&
               shifts[worker_no, shift_no+1] in
               DISALLOWED_SHIFTS_SEQS[shifts[worker_no, shift_no]]

                penalty += PEN_DISALLOWED_SHIFT_SEQ
                @debug "Worker '$(workers[worker_no])' has a disallowed shift sequence " *
                       "on day '$(shift_no)': " *
                       "$(shifts[worker_no, shift_no]) -> $(shifts[worker_no, shift_no + 1])"
            end

            # long break between weeks does not count
            if shift_no != length(DAYS_OF_WEEK) &&
               shifts[worker_no, shift_no] in LONG_BREAK_SEQ[1] &&
               shifts[worker_no, shift_no+1] in LONG_BREAK_SEQ[2]

                long_breaks[Int(ceil(shift_no / length(DAYS_OF_WEEK)))] = true
            end
        end

        if false in long_breaks
            for (week_no, value) in enumerate(long_breaks)
                if value == false
                    penalty += PEN_NO_LONG_BREAK
                    @debug "Worker '$(workers[worker_no])' does not have a long break in week: '$(week_no)'"
                end
            end
        end
    end
    return penalty
end

function check_workers_overtime(workers, shifts, workers_info)
    penalty = 0
    worker_worktime = Dict()
    weeks_num = ceil(Int, size(shifts, 2) / length(DAYS_OF_WEEK))

    for worker_no in axes(shifts, 1)
        exempted_days = count(s -> (s in SHIFTS_EXEMPT), shifts[worker_no, :])
        hours_per_week = WORK_TIME[workers_info["time"][workers[worker_no]]]
        req_worktime = Int(weeks_num * hours_per_week - hours_per_week / 5 * exempted_days)

        act_worktime = sum(map(s -> SHIFTS_TIME[s], shifts[worker_no, :]))

        worker_worktime[workers[worker_no]] = act_worktime - req_worktime
    end

    for (worker, overtime) in worker_worktime
        penalty += if overtime > 0
            @debug "Worker '$(worker)' has overtime hours: '$(overtime)'"
            overtime
        elseif overtime < 0
            @debug "Worker '$(worker)' has undertime hours: '$(abs(overtime))' - half penalty for now."
            ceil(Int, overtime / 2)
        else
            0
        end
    end

    overtimes = filter(s -> (s > 0), collect(values(worker_worktime)))
    worktime_std = if length(overtimes) > 1
        round(Int, std(overtimes))
    else
        0
    end

    if worktime_std > MAX_STD ||
       (s -> (s > MAX_OVER_TIME)) in collect(values(worker_worktime))
        # in this case soft constraints are kind of hard ones :)
        return length(workers) * MAX_OVER_TIME + MAX_STD
    end

    @debug "Overtime total: $((isempty(overtimes)) ? 0 : sum(overtimes)), std: $(worktime_std)"
    return penalty
end

end # ScheduleScore

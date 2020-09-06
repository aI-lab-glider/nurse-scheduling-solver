module ScheduleScore

export score

using Statistics
using ..NurseSchedules


function score(
    schedule_shifts::ScheduleShifts,
    month_info::Dict{String,Any},
    workers_info::Dict{String,Any},
)::Int
    workers, shifts = schedule_shifts
    penalty = 0

    penalty += ck_workers_presence(schedule_shifts, month_info, workers_info)


    penalty += ck_workers_rights(workers, shifts)

    penalty += ck_workers_worktime(workers, shifts, workers_info)

    return penalty
end

function ck_workers_presence(
    schedule_shifts::ScheduleShifts,
    month_info::Dict{String,Any},
    workers_info::Dict{String,Any},
)::Int
    workers, shifts = schedule_shifts
    penalty = 0
    for day_no in axes(shifts, 2)
        day_shifts = shifts[:, day_no]
        penalty += ck_workers_to_children(day_no, day_shifts, month_info)
        penalty += ck_nurse_presence(day_no, workers, day_shifts, workers_info)
    end
    if penalty > 0
        @debug "Lacking workers total penalty: $(penalty)"
    end
    return penalty
end

function ck_workers_to_children(
    day::Int,
    day_shifts::Array{String,1},
    month_info::Dict{String,Any},
)::Int
    penalty = 0
    req_nrs_day::Int = ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_DAY)
    req_nrs_night::Int = ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_NIGHT)

    act_nrs_night = count(s -> (s in SHIFTS_NIGHT), day_shifts)

    act_nrs_day = count(s -> (s in SHIFTS_FULL_DAY), day_shifts)
    act_nrs_day +=
        min(count(s -> (s == R), day_shifts), count(s -> (s in [P, PN]), day_shifts))
    # night shifts complement day shifts
    act_nrs_day = min(act_nrs_day, act_nrs_night)

    missing_nrs_day = req_nrs_day - act_nrs_day
    missing_nrs_day = (missing_nrs_day < 0) ? 0 : missing_nrs_day
    missing_nrs_night = req_nrs_night - act_nrs_night
    missing_nrs_night = (missing_nrs_night < 0) ? 0 : missing_nrs_night

    # penalty is charged only for nurses lacking during the day
    day_pen = missing_nrs_day * PEN_LACKING_WORKER
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
    return penalty
end

function ck_nurse_presence(day::Int, wrks, day_shifts, workers_info)
    penalty = 0
    nrs_shifts = [
        shift
        for
        (wrk, shift) in zip(wrks, day_shifts) if workers_info["type"][wrk] == "NURSE"
    ]
    if isempty(SHIFTS_MORNING ∩ nrs_shifts)
        @debug "Lacking a nurse in the morning on day '$day'"
        penalty += PEN_LACKING_NURSE
    end
    if isempty(SHIFTS_AFTERNOON ∩ nrs_shifts)
        @debug "Lacking a nurse in the afternoon on day '$day'"
        penalty += PEN_LACKING_NURSE
    end
    if isempty(SHIFTS_NIGHT ∩ nrs_shifts)
        @debug "Lacking a nurse in the night on day '$day'"
        penalty += PEN_LACKING_NURSE
    end
    return penalty
end

function ck_workers_rights(workers, shifts)::Int
    penalty = 0
    for worker_no in axes(shifts, 1)
        long_breaks = fill(false, ceil(Int, size(shifts, 2) / length(DAYS_OF_WEEK)))

        for shift_no in axes(shifts, 2)
            # do not check rights on the last day
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

            if shift_no % length(DAYS_OF_WEEK) != 0 && # long break between weeks does not count
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

function ck_workers_worktime(workers, shifts, workers_info)::Int
    penalty = 0
    workers_worktime = Dict()
    weeks_num = ceil(Int, size(shifts, 2) / length(DAYS_OF_WEEK))

    for worker_no in axes(shifts, 1)
        exempted_days = count(s -> (s in SHIFTS_EXEMPT), shifts[worker_no, :])
        hours_per_week = WORK_TIME[workers_info["time"][workers[worker_no]]]
        req_worktime = Int(weeks_num * hours_per_week - hours_per_week / 5 * exempted_days)

        act_worktime = sum(map(s -> SHIFTS_TIME[s], shifts[worker_no, :]))

        workers_worktime[workers[worker_no]] = act_worktime - req_worktime
    end

    for (worker, overtime) in workers_worktime
        penalty += if overtime > MAX_OVER_TIME
            @debug "Worker '$(worker)' has overtime hours: '$(overtime)'"
            overtime - MAX_OVER_TIME
        elseif overtime < 0
            @debug "Worker '$(worker)' has undertime hours: '$(abs(overtime))'"
            abs(overtime)
        else
            0
        end
    end

    @debug "Total penalty from undertime and overtime: $(penalty)"
    return penalty
end

end # ScheduleScore

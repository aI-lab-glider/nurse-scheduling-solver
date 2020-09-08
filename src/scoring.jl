module ScheduleScoring

export score

import Base.+

using ..NurseSchedules:
    Schedule,
    ScoringResult,
    ScheduleShifts,
    Shifts,
    Workers,
    R, P, D, N, DN, PN, W, U, L4,
    CHANGEABLE_SHIFTS,
    SHIFTS_FULL_DAY,
    SHIFTS_NIGHT,
    SHIFTS_MORNING,
    SHIFTS_AFTERNOON,
    SHIFTS_EXEMPT,
    SHIFTS_TIME,
    REQ_CHLDN_PER_NRS_DAY,
    REQ_CHLDN_PER_NRS_NIGHT,
    DISALLOWED_SHIFTS_SEQS,
    LONG_BREAK_SEQ,
    MAX_OVERTIME,
    MAX_UNDERTIME,
    PEN_LACKING_NURSE,
    PEN_LACKING_WORKER,
    PEN_DISALLOWED_SHIFT_SEQ,
    PEN_NO_LONG_BREAK,
    WORKTIME,
    DAYS_OF_WEEK,
    TimeOfDay

(+)(l::ScoringResult, r::ScoringResult) =
    ScoringResult((l.penalty + r.penalty, vcat(l.errors, r.errors)))

function score(
    schedule_shifts::ScheduleShifts,
    month_info::Dict{String,Any},
    workers_info::Dict{String,Any},
)::ScoringResult
    workers, shifts = schedule_shifts
    score_res = ScoringResult((0, []))

    score_res += ck_workers_presence(schedule_shifts, month_info, workers_info)

    score_res += ck_workers_rights(workers, shifts)

    score_res += ck_workers_worktime(workers, shifts, workers_info)

    return score_res
end

function ck_workers_presence(
    schedule_shifts::ScheduleShifts,
    month_info::Dict{String,Any},
    workers_info::Dict{String,Any},
)::ScoringResult
    workers, shifts = schedule_shifts
    score_res = ScoringResult((0, []))
    for day_no in axes(shifts, 2)
        day_shifts = shifts[:, day_no]
        score_res += ck_workers_to_children(day_no, day_shifts, month_info)
        score_res += ck_nurse_presence(day_no, workers, day_shifts, workers_info)
    end
    if score_res.penalty > 0
        @debug "Lacking workers total penalty: $(score_res.penalty)"
    end
    return score_res
end

function ck_workers_to_children(
    day::Int,
    day_shifts::Vector{String},
    month_info::Dict{String,Any},
)::ScoringResult
    penalty = 0
    errors = Vector{Dict{String,Any}}()

    req_wrk_day::Int = ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_DAY)
    req_wrk_night::Int = ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_NIGHT)

    act_wrk_night = count(s -> (s in SHIFTS_NIGHT), day_shifts)

    act_wrk_day = count(s -> (s in SHIFTS_FULL_DAY), day_shifts)
    act_wrk_day +=
        min(count(s -> (s == R), day_shifts), count(s -> (s in [P, PN]), day_shifts))
    # night shifts complement day shifts
    act_wrk_day = min(act_wrk_day, act_wrk_night)

    missing_wrk_day = req_wrk_day - act_wrk_day
    missing_wrk_day = (missing_wrk_day < 0) ? 0 : missing_wrk_day
    missing_wrk_night = req_wrk_night - act_wrk_night
    missing_wrk_night = (missing_wrk_night < 0) ? 0 : missing_wrk_night

    # penalty is charged only for workers lacking during daytime
    day_pen = missing_wrk_day * PEN_LACKING_WORKER
    penalty += day_pen

    if day_pen > 0
        error_details = ""
        if missing_wrk_day > 0
            error_details *= "\nExpected '$(req_wrk_day)', got '$(act_wrk_day)' in the day."
            push!(
                errors,
                Dict(
                    "code" => "WND",
                    "day" => day,
                    "required" => req_wrk_day,
                    "actual" => act_wrk_day,
                ),
            )
        end
        if missing_wrk_night > 0
            error_details *= "\nExpected '$(req_wrk_night)', got '$(act_wrk_night)' at night."
            push!(
                errors,
                Dict(
                    "code" => "WNN",
                    "day" => day,
                    "required" => req_wrk_night,
                    "actual" => act_wrk_night,
                ),
            )
        end
        @debug "There is a lack of staff on day '$day'." * error_details
    end
    return ScoringResult((penalty, errors))
end

function ck_nurse_presence(day::Int, wrks, day_shifts, workers_info)::ScoringResult
    penalty = 0
    errors = Vector{Dict{String,Any}}()
    nrs_shifts = [
        shift
        for
        (wrk, shift) in zip(wrks, day_shifts) if workers_info["type"][wrk] == "NURSE"
    ]
    if isempty(SHIFTS_MORNING ∩ nrs_shifts)
        @debug "Lacking a nurse in the morning on day '$day'"
        penalty += PEN_LACKING_NURSE
        push!(
            errors,
            Dict("code" => "AON", "day" => day, "time_of_day" => string(TimeOfDay.MORNING)),
        )
    end
    if isempty(SHIFTS_AFTERNOON ∩ nrs_shifts)
        @debug "Lacking a nurse in the afternoon on day '$day'"
        penalty += PEN_LACKING_NURSE
        push!(
            errors,
            Dict(
                "code" => "AON",
                "day" => day,
                "time_of_day" => string(TimeOfDay.AFTERNOON),
            ),
        )
    end
    if isempty(SHIFTS_NIGHT ∩ nrs_shifts)
        @debug "Lacking a nurse in the night on day '$day'"
        penalty += PEN_LACKING_NURSE
        push!(
            errors,
            Dict("code" => "AON", "day" => day, "time_of_day" => string(TimeOfDay.NIGHT)),
        )
    end
    return ScoringResult((penalty, errors))
end

function ck_workers_rights(workers, shifts)::ScoringResult
    penalty = 0
    errors = Vector{Dict{String,Any}}()
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
                @debug "The worker '$(workers[worker_no])' has a disallowed shift sequence " *
                       "on day '$(shift_no + 1)': " *
                       "$(shifts[worker_no, shift_no]) -> $(shifts[worker_no, shift_no + 1])"
                push!(
                    errors,
                    Dict(
                        "code" => "DSS",
                        "day" => shift_no + 1,
                        "worker" => workers[worker_no],
                        "preceding" => shifts[worker_no, shift_no],
                        "succeeding" => shifts[worker_no, shift_no+1],
                    ),
                )
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
                    @debug "The worker '$(workers[worker_no])' does not have a long break in week: '$(week_no)'"
                    push!(
                        errors,
                        Dict(
                            "code" => "LLB",
                            "week" => week_no,
                            "worker" => workers[worker_no],
                        ),
                    )
                end
            end
        end
    end
    return ScoringResult((penalty, errors))
end

function ck_workers_worktime(workers, shifts, workers_info)::ScoringResult
    penalty = 0
    errors = Vector{Dict{String,Any}}()
    workers_worktime = Dict{String,Int}()
    weeks_num = ceil(Int, size(shifts, 2) / length(DAYS_OF_WEEK))

    for worker_no in axes(shifts, 1)
        exempted_days = count(s -> (s in SHIFTS_EXEMPT), shifts[worker_no, :])
        hours_per_week = WORKTIME[workers_info["time"][workers[worker_no]]]
        req_worktime = Int(weeks_num * hours_per_week - hours_per_week / 5 * exempted_days)

        act_worktime = sum(map(s -> SHIFTS_TIME[s], shifts[worker_no, :]))

        workers_worktime[workers[worker_no]] = act_worktime - req_worktime
    end

    for (worker, overtime) in workers_worktime
        penalty += if overtime > MAX_OVERTIME
            @debug "The worker '$(worker)' has too much overtime: '$(overtime)'"
            push!(
                errors,
                Dict(
                    "code" => "WOH",
                    "hours" => overtime - MAX_OVERTIME,
                    "worker" => worker,
                ),
            )
            overtime - MAX_OVERTIME
        elseif overtime < -MAX_UNDERTIME
            undertime = abs(overtime) - MAX_UNDERTIME
            @debug "The worker '$(worker)' has too much undertime: '$(undertime)'"
            push!(errors, Dict("code" => "WUH", "hours" => undertime, "worker" => worker))
            undertime
        else
            0
        end
    end
    @debug "Total penalty from undertime and overtime: $(penalty)"
    return ScoringResult((penalty, errors))
end

end # ScheduleScore

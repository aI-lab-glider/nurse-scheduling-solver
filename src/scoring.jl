# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ScheduleScoring

export score

import Base.+

using ..NurseSchedules:
    Schedule,
    get_penalties,
    get_workers_info,
    get_month_info,
    get_shift_options,
    get_disallowed_sequences,
    get_changeable_shifts,
    get_exempted_shifts,
    get_earliest_shift_begin,
    get_latest_shift_end,
    get_day,
    get_period_range,
    get_interval_length,
    sum_segments,
    ScoringResult,
    ScoringResultOrPenalty,
    ScheduleShifts,
    Shifts,
    Workers,
    REQ_CHLDN_PER_NRS_DAY,
    PERIOD_BEGIN,
    REQ_CHLDN_PER_NRS_NIGHT,
    LONG_BREAK_HOURS,
    MAX_OVERTIME,
    MAX_UNDERTIME,
    WORKTIME_BASE,
    WEEK_DAYS_NO,
    NUM_WORKING_DAYS,
    DAY_HOURS_NO,
    SUNDAY_NO,
    WORKTIME_DAILY,
    PERIOD_BEGIN,
    Constraints,
    WorkerType,
    ErrorCode,
    within,
    get_shift_length

(+)(l::ScoringResult, r::ScoringResult) =
    ScoringResult((l.penalty + r.penalty, vcat(l.errors, r.errors)))

function score(
    schedule_shifts::ScheduleShifts,
    schedule::Schedule;
    return_errors::Bool = false,
)::ScoringResultOrPenalty
    score_res = ScoringResult((0, []))

    score_res += ck_workers_presence(schedule_shifts, schedule)

    score_res += ck_workers_rights(schedule_shifts, schedule)

    score_res += ck_workers_worktime(schedule_shifts, schedule)

    if return_errors
        score_res
    else
        score_res.penalty
    end
end

function ck_workers_presence(
    schedule_shifts::ScheduleShifts,
    schedule::Schedule,
)::ScoringResult
    workers, shifts = schedule_shifts
    score_res = ScoringResult((0, []))
    for day_no in axes(shifts, 2)
        day_shifts = shifts[:, day_no]
        score_res += ck_workers_to_children(day_no, day_shifts, schedule)
        score_res += ck_nurse_presence(day_no, workers, day_shifts, schedule)
        score_res += ck_daily_workers_teams(day_shifts, day_no, workers, schedule)
    end
    if score_res.penalty > 0
        @debug "Lacking workers total penalty: $(score_res.penalty)"
    end
    return score_res
end

# WNN/WND
function ck_workers_to_children(
    day::Int,
    day_shifts::Vector{String},
    schedule::Schedule,
)::ScoringResult
    shift_info = get_shift_options(schedule)
    month_info = get_month_info(schedule)
    penalties = get_penalties(schedule)

    if penalties[string(Constraints.PEN_LACKING_WORKER)] == 0
        return ScoringResult((0, []))
    end

    errors = Vector{Dict{String,Any}}()

    req_wrk_day::Int =
        ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_DAY) -
        month_info["extra_workers"][day]
    req_wrk_night::Int = ceil(month_info["children_number"][day] / REQ_CHLDN_PER_NRS_NIGHT)

    day_begin, day_end = get_day(schedule)
    day_segments = []
    day_segments_begin = nothing
    night_segments = []
    night_segments_begin = nothing
    
    act_wrk_day = req_wrk_day
    act_wrk_night = req_wrk_night

    for hour in get_period_range()
        current_workers = count([
            within(hour, shift_info[shift])
            for shift in day_shifts    
        ])
        if hour >= day_begin && hour < day_end
        # day
            act_wrk_day = min(act_wrk_day, current_workers)
            if !isnothing(night_segments_begin)
               push!(night_segments, (night_segments_begin, hour))
               night_segments_begin = nothing
            end
            if current_workers < req_wrk_day 
                if isnothing(day_segments_begin)
                    day_segments_begin = hour
                end
            elseif !isnothing(day_segments_begin)
                push!(day_segments, (day_segments_begin, hour))
                day_segments_begin = nothing
            end
        else
        # night
            act_wrk_night = min(act_wrk_night, current_workers)
            if !isnothing(day_segments_begin)
                push!(day_segments, (day_segments_begin, hour))
                day_segments_begin = nothing
            end
            if current_workers < req_wrk_night
                if isnothing(night_segments_begin)
                    night_segments_begin = hour
                end
            elseif !isnothing(night_segments_begin)
                push!(night_segments, (night_segments_begin, hour))
                night_segments_begin = nothing
            end
        end
    end

    if !isnothing(day_segments_begin)
        first_block = get(day_segments, 1, (-1, -1))
        if first_block[1] == 1
            popfirst!(day_segments)
            push!(day_segments, (day_segments_begin, first_block[2]))
        else
            push!(day_segments, (day_segments_begin, PERIOD_BEGIN))
        end
    elseif !isnothing(night_segments_begin)
        first_block = get(night_segments, 1, (-1, -1))
        if first_block[1] == 1
            popfirst!(night_segments)
            push!(night_segments, (night_segments_begin, first_block[2]))
        else
            push!(night_segments, (night_segments_begin, PERIOD_BEGIN))
        end
    end


    # penalty is charged only for workers lacking during daytime
    penalty = (req_wrk_day - act_wrk_day) * penalties[string(Constraints.PEN_LACKING_WORKER)]
    penalty += (req_wrk_night - act_wrk_night) * penalties[string(Constraints.PEN_LACKING_WORKER)]

    if penalty > 0
        error_details = ""
        if req_wrk_day > act_wrk_day
            error_details *= "\nExpected '$(req_wrk_day)', got '$(act_wrk_day)' in the day."
            push!(
                errors,
                Dict(
                    "code" => string(ErrorCode.WORKERS_NO_DURING_DAY),
                    "day" => day,
                    "required" => req_wrk_day,
                    "actual" => act_wrk_day,
                    "segments" => day_segments
                ),
            )
        end
        if req_wrk_night > act_wrk_night
            error_details *= "\nExpected '$(req_wrk_night)', got '$(act_wrk_night)' at night."
            push!(
                errors,
                Dict(
                    "code" => string(ErrorCode.WORKERS_NO_DURING_NIGHT),
                    "day" => day,
                    "required" => req_wrk_night,
                    "actual" => act_wrk_night,
                    "segments" => night_segments
                ),
            )
        end
        @debug "Insufficient staff on day '$day'." * error_details
    end
    return ScoringResult((penalty, errors))
end

# AON
function ck_nurse_presence(day::Int, wrks, day_shifts, schedule::Schedule)::ScoringResult
    shift_info = get_shift_options(schedule)
    workers_info = get_workers_info(schedule)
    penalties = get_penalties(schedule)

    if penalties[string(Constraints.PEN_LACKING_NURSE)] == 0
        return ScoringResult((0, []))
    end

    penalty = 0
    errors = Vector{Dict{String,Any}}()

    #Get set of nurses shifts

    hours_pop = [
        count([
            within(hour, shift_info[shift])
            for
            (wrk, shift) in zip(wrks, day_shifts) if
            workers_info["type"][wrk] == string(WorkerType.NURSE)
        ]) for hour = 1:24
    ]

    empty_segments = []
    segment_begin = nothing

    for hour in get_period_range()
        if hours_pop[hour] == 0
            penalty += penalties[string(Constraints.PEN_LACKING_NURSE)]
            if isnothing(segment_begin)
                segment_begin = hour
            end
        elseif !isnothing(segment_begin)
            push!(empty_segments, (segment_begin, hour))
            segment_begin = nothing
        end
    end

    # Close last
    if !isnothing(segment_begin)
        push!(empty_segments, (segment_begin, PERIOD_BEGIN))
    end

    if empty_segments != []
        @debug "Lacking a nurse at on day '$day'"
        push!(
            errors,
            Dict(
                "code" => string(ErrorCode.ALWAYS_AT_LEAST_ONE_NURSE),
                "day" => day,
                "segments" => empty_segments,
            ),
        )
    end
    return ScoringResult((penalty, errors))
end

#WMT
function ck_daily_workers_teams(
    day_shifts::Vector{String},
    day::Int,
    workers::Workers,
    schedule::Schedule
)::ScoringResult
    penalty = 0
    errors = []
    penalties = get_penalties(schedule)
    workers_info = get_workers_info(schedule)
    shifts = get_shift_options(schedule)

    if penalties[string(Constraints.PEN_MULTIPLE_TEAMS)] == 0 || !haskey(workers_info, "team")
        return ScoringResult((0, []))
    end

    worker_teams = map(w -> workers_info["team"][w], workers)

    teams_hourly = [
        size(
        unique(
            team
            for (worker, team) in enumerate(worker_teams)
            if within(hour, shifts[day_shifts[worker]])
        ), 1)
        for hour = 1:24
    ]
    workers_hourly = [
        [
            worker 
            for (num, worker) in enumerate(workers)
            if within(hour, shifts[day_shifts[num]]) 
        ]
        for hour = 1:24
    ]

    for hour in get_period_range()
        if teams_hourly[hour] > 1
            penalty += penalties[string(Constraints.PEN_MULTIPLE_TEAMS)] * (teams_hourly[hour] - 1)
            push!(
                errors,
                Dict(
                    "code" => string(ErrorCode.MULTIPLE_TEAMS),
                    "day" => day,
                    "hour" => hour,
                    "workers" => workers_hourly[hour]
            ))
        end
    end
    return ScoringResult((penalty, errors))
end

### LLB + DSS
function ck_workers_rights(
    schedule_shitfs::ScheduleShifts,
    schedule::Schedule,
)::ScoringResult
    workers, shifts = schedule_shitfs
    penalties = get_penalties(schedule)

    if penalties[string(Constraints.PEN_DISALLOWED_SHIFT_SEQ)] == 0
        return ck_workers_long_breaks(schedule_shitfs, schedule)
    end

    disallowed_shift_seq = get_disallowed_sequences(schedule)

    penalty = 0
    errors = Vector{Dict{String,Any}}()
    for worker_no in axes(shifts, 1)
        for shift_no in axes(shifts, 2)
            # do not check rights on the last day
            if shift_no == size(shifts, 2)
                continue
            end

            if shifts[worker_no, shift_no] in keys(disallowed_shift_seq) &&
               shifts[worker_no, shift_no + 1] in
               disallowed_shift_seq[shifts[worker_no, shift_no]]

                penalty += penalties[string(Constraints.PEN_DISALLOWED_SHIFT_SEQ)]
                @debug "The worker '$(workers[worker_no])' has a disallowed shift sequence " *
                       "on day '$(shift_no + 1)': " *
                       "$(shifts[worker_no, shift_no]) -> $(shifts[worker_no, shift_no + 1])"
                push!(
                    errors,
                    Dict(
                        "code" => string(ErrorCode.DISALLOWED_SHIFT_SEQ),
                        "day" => shift_no + 1,
                        "worker" => workers[worker_no],
                        "preceding" => shifts[worker_no, shift_no],
                        "succeeding" => shifts[worker_no, shift_no + 1],
                    ),
                )
            end
        end
    end
    return ScoringResult((penalty, errors)) + ck_workers_long_breaks(schedule_shitfs, schedule)
end

# LLB
function ck_workers_long_breaks(
    schedule_shitfs::ScheduleShifts,
    schedule::Schedule
)::ScoringResult
    penalty = 0
    errors = Vector{Dict{String,Any}}()
    workers, shifts = schedule_shitfs
    penalties = get_penalties(schedule)
    
    if penalties[string(Constraints.PEN_NO_LONG_BREAK)] == 0
        return ScoringResult((0, []))
    end

    weeks_no = ceil(Int, size(shifts, 2) / WEEK_DAYS_NO)
    shift_types = get_shift_options(schedule)

    for week in 1:weeks_no
        first_week_day = (week-1) * WEEK_DAYS_NO + 1
        last_week_day = week * WEEK_DAYS_NO
        for worker_no in axes(shifts, 1)
            has_break = false
            break_time = 24 - get_latest_shift_end(schedule)
            for shift_no in first_week_day:last_week_day
                shift = shifts[worker_no, shift_no]
                # Changeable == working
                if shift in keys(get_changeable_shifts(schedule))
                    break_time += shift_types[shift]["from"]
                    if break_time >= LONG_BREAK_HOURS
                        has_break = true
                        break
                    end
                    break_time = if shift_types[shift]["to"] > shift_types[shift]["from"]
                        24 - shift_types[shift]["to"]
                    else
                        - shift_types[shift]["to"]
                    end
                else
                    break_time += 24
                    if break_time >= LONG_BREAK_HOURS
                        has_break = true
                        break
                    end
                end
            end
            break_time += get_earliest_shift_begin(schedule)
            if break_time >= LONG_BREAK_HOURS
                has_break = true
            end
            if !has_break
                penalty += penalties[string(Constraints.PEN_NO_LONG_BREAK)]
                @debug "The worker '$(workers[worker_no])' does not have a long break in week: '$(week)'"
                push!(
                    errors,
                    Dict(
                        "code" => string(ErrorCode.LACKING_LONG_BREAK),
                        "week" => week,
                        "worker" => workers[worker_no],
                ))
            end
        end
    end
    return ScoringResult((penalty, errors))
end

function ck_workers_worktime(
    schedule_shifts::ScheduleShifts,
    schedule::Schedule,
)::ScoringResult
    shift_info = get_shift_options(schedule)
    month_info = get_month_info(schedule)
    workers_info = get_workers_info(schedule)
    workers, shifts = schedule_shifts

    penalty = 0
    errors = Vector{Dict{String,Any}}()
    workers_worktime = Dict{String,Int}()

    num_weeks = ceil(Int, size(shifts, 2) / WEEK_DAYS_NO)
    num_days = num_weeks * NUM_WORKING_DAYS

    max_overtime = num_weeks * MAX_OVERTIME
    max_undertime = num_weeks * MAX_UNDERTIME

    # Get list of holiday dates, filter out sundays and count them
    holidays_no = length(filter(
        day_no -> day_no % WEEK_DAYS_NO != SUNDAY_NO,
        get(month_info, "holidays", Int[]),
    ))

    for worker_no in axes(shifts, 1)
        exempted_days_no = holidays_no
        worker_shifts = shifts[worker_no, :]

        while !isempty(worker_shifts)
            week_exempted_days_no =
                count(s -> (s in keys(get_exempted_shifts(schedule))), splice!(worker_shifts, 1:WEEK_DAYS_NO))
            exempted_days_no += if week_exempted_days_no > NUM_WORKING_DAYS
                NUM_WORKING_DAYS
            else
                week_exempted_days_no
            end
        end

        hours_per_day::Float32 = workers_info["time"][workers[worker_no]] * WORKTIME_DAILY

        req_worktime = (num_days - exempted_days_no) * hours_per_day

        act_worktime = sum(map(s -> get_shift_length(shift_info[s]), shifts[worker_no, :]))

        workers_worktime[workers[worker_no]] = act_worktime - req_worktime
    end

    for (worker, overtime) in workers_worktime
        penalty += if overtime > max_overtime
            @debug "The worker '$(worker)' has too much overtime: '$(overtime)'"
            push!(
                errors,
                Dict(
                    "code" => string(ErrorCode.WORKER_OVERTIME_HOURS),
                    "hours" => overtime - max_overtime,
                    "worker" => worker,
                ),
            )
            overtime - max_overtime
        elseif overtime < -max_undertime
            @debug "The worker '$(worker)' has too much undertime: '$(abs(overtime))'"
            undertime = abs(overtime) - max_undertime
            push!(
                errors,
                Dict(
                    "code" => string(ErrorCode.WORKER_UNDERTIME_HOURS),
                    "hours" => undertime,
                    "worker" => worker,
                ),
            )
            undertime
        else
            0
        end
    end
    if penalty > 0
        @debug "Total penalty from undertime and overtime: $(penalty)"
        @debug "Max overtime hours: '$(max_overtime)'"
        @debug "Max undertime hours: '$(max_undertime)'"
    end
    return ScoringResult((penalty, errors))
end
end # ScheduleScoring

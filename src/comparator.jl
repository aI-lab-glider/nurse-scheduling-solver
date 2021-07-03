# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ScheduleComparing

export cmp_workers_worktime

using ..NurseSchedules:
    Schedule,
    get_shift_options,
    get_month_info,
    get_shift_length,
    get_workers_info,
    WEEK_DAYS_NO,
    NUM_WORKING_DAYS,
    MAX_OVERTIME,
    MAX_UNDERTIME,
    WORKTIME_DAILY,
    W_ID,
    SUNDAY_NO,
    ErrorCode,
    ScheduleShifts,
    ScoringResult,
    is_working,
    get_hours_reduction

"""
    Evaluates current workers worktime restrictions based on a schedules from the beginning of the month and at the end
    Args:
        old_schedule::ScheduleShifts    - array containing shcedule from the beginning of the month
        new_schedule::ScheduleShifts    - array containing shcedule from the end of the month
        schedule::Schedule              - Schedule metadata for a given month
    Returns:
        ScoringResult                   - Evaluated score with errors description
        
"""
function cmp_workers_worktime(
    old_schedule::ScheduleShifts,
    new_schedule::ScheduleShifts,
    schedule::Schedule
)::ScoringResult
    shift_info = get_shift_options(schedule)
    month_info = get_month_info(schedule)
    workers_info = get_workers_info(schedule)
    workers, old_shifts = old_schedule
    _, new_shifts = new_schedule

    penalty = 0
    errors = Vector{Dict{String, Any}}()

    num_weeks = ceil(Int, size(old_shifts, 2) / WEEK_DAYS_NO)
    num_days = num_weeks * NUM_WORKING_DAYS

    max_overtime = num_weeks * MAX_OVERTIME
    max_undertime = num_weeks * MAX_UNDERTIME

    # Current assumption
    # Reduce norm only when working shift is replaced by non-working

    holidays_no = length(filter(
        day_no -> day_no % WEEK_DAYS_NO != SUNDAY_NO,
        get(month_info, "holidays", Int[])
    ))

    for worker_no in axes(old_shifts, 1)
        # Catch all hours reduction
        negative_hours = sum(
            map(
                pos -> get_hours_reduction(shift_info[new_shifts[pos]]),     
                filter(
                    pos -> 
                        is_working(shift_info[old_shifts[worker_no, pos]]) && 
                        !is_working(shift_info[new_shifts[worker_no, pos]]) &&
                        new_shifts[worker_no, pos] != W_ID,
                    keys(old_shifts[worker_no, :]) 
        )))

        hours_per_day::Float32 = workers_info["time"][workers[worker_no]] * WORKTIME_DAILY
        req_worktime = ((num_days - holidays_no) *  hours_per_day) - negative_hours
        act_worktime = sum(map(s -> get_shift_length(shift_info[s]), new_shifts[worker_no, :]))

        worktime = act_worktime - req_worktime

        if worktime > max_overtime
            pen_diff = worktime - max_overtime
            @debug "The worker '$(worker_no)' has too much overtime: '$(pen_diff)'"
            push!(
                errors,
                Dict(
                    "code" => string(ErrorCode.WORKER_OVERTIME_HOURS),
                    "hours" => pen_diff,
                    "worker" => worker_no,
            ))
            penalty += pen_diff
        elseif worktime < -max_undertime
            pen_diff = -(worktime+max_undertime)
            @debug "The worker '$(worker_no)' has too much undertime: '$(pen_diff)'"
            push!(
                errors,
                Dict(
                    "code" => string(ErrorCode.WORKER_UNDERTIME_HOURS),
                    "hours" => pen_diff,
                    "worker" => worker_no,
            ))
            penalty += pen_diff
        end
    end

    if penalty > 0
        @debug "Total penalty from undertime and overtime: $(penalty)"
        @debug "Max overtime hours: '$(max_overtime)'"
        @debug "Max undertime hours: '$(max_undertime)"
    end
    ScoringResult((penalty, errors))
end

end # Module
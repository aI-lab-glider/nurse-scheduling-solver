# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# CUSTOM TYPES
#
# Scoring
ScoringResult = @NamedTuple{penalty::Int, errors::Vector{Dict{String,Any}}}
ScoringResultOrPenalty = Union{ScoringResult,Int}
# Schedule related
Workers = Vector{String}
Shifts = Array{String,2}
ScheduleShifts = Tuple{Workers,Shifts}
# Neighborhood
@se Mutation begin
    ADD => "ADDITION"
    DEL => "DELETION"
    SWP => "SWAP"
end
IntOrTuple = Union{Int,Tuple{Int,Int}}
StringOrNothing = Union{String,Nothing}
MutationRecipe = @NamedTuple{
    type::Mutation.MutationEnum,
    day::Int,
    wrk_no::IntOrTuple,
    optional_info::StringOrNothing,
}

# day free dict
const W_DICT = Dict("from" => 7,
                    "to" => 15,
                    "is_working_shift" => false)

const REQ_CHLDN_PER_NRS_DAY = 3
const REQ_CHLDN_PER_NRS_NIGHT = 5

# there has to be such a seq each week
const LONG_BREAK_HOURS = 35

# under and overtime pen is equal to hours from <0, MAX_OVERTIME>
const MAX_OVERTIME = 10 # scaled by the number of weeks
const MAX_UNDERTIME = 0 # scaled by the number of weeks

const CONFIG = JSON.parsefile("config/default/priorities.json")
const SHIFTS = JSON.parsefile("config/default/shifts.json")
const DAY_BEGIN = 6
const NIGHT_BEGIN = 22
 
const PERIOD_BEGIN = 7

# weekly worktime
const WORKTIME_BASE = 40

const DAY_HOURS_NO = 24
const WEEK_DAYS_NO = 7
const NUM_WORKING_DAYS = 5
const SUNDAY_NO = 0

const WORKTIME_DAILY = WORKTIME_BASE / NUM_WORKING_DAYS

@se Constraints begin
    PEN_LACKING_NURSE => "AON"
    PEN_LACKING_WORKER => "WND"
    PEN_LACKING_WORKER_NIGHT => "WNN"
    PEN_MULTIPLE_TEAMS => "MWT"
    PEN_NO_LONG_BREAK => "LLB"
    PEN_DISALLOWED_SHIFT_SEQ => "DSS"
end

@se WorkerType begin
    NURSE => "NURSE"
    OTHER => "OTHER"
end

@se ErrorCode begin
    ALWAYS_AT_LEAST_ONE_NURSE => "AON"
    WORKERS_NO_DURING_DAY => "WND"
    WORKERS_NO_DURING_NIGHT => "WNN"
    MULTIPLE_TEAMS => "MWT"
    DISALLOWED_SHIFT_SEQ => "DSS"
    LACKING_LONG_BREAK => "LLB"
    WORKER_UNDERTIME_HOURS => "WUH"
    WORKER_OVERTIME_HOURS => "WOH"
end

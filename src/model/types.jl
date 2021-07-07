# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Custom types used across the project
module types

using SuperEnum

import Base.+

# Super enums

# Neighborhood
@se Mutation begin
    ADD => "ADDITION"
    DEL => "DELETION"
    SWP => "SWAP"
end

@se Constraints begin
    PEN_LACKING_NURSE => "AON"
    PEN_LACKING_WORKER => "WND"
    PEN_LACKING_WORKER_NIGHT => "WNN"
    PEN_MULTIPLE_TEAMS => "WTC"
    PEN_NO_LONG_BREAK => "LLB"
    PEN_DISALLOWED_SHIFT_SEQ => "DSS"
end

@se WorkerType begin
    NURSE => "NURSE"
    OTHER => "OTHER"
end

@se ContractType begin
    EMPLOYMENT => "EMPLOYMENT"
    CIVIL => "CIVIL"
end

@se ShiftType begin
    WORKING => "WORKING"
    NONWORKING => "NONWORKING"
    UTIL => "UTIL"
    NONWORKING_DIFF => "NONWORKING_DIFF"
end

@se BasicShift begin
    NONWORKING => "W"
    SICK_LEAVE => "L4"
    VACATION => "U"
end

@se ErrorCode begin
    ALWAYS_AT_LEAST_ONE_NURSE => "AON"
    WORKERS_NO_DURING_DAY => "WND"
    WORKERS_NO_DURING_NIGHT => "WNN"
    MULTIPLE_TEAMS => "WTC"
    DISALLOWED_SHIFT_SEQ => "DSS"
    LACKING_LONG_BREAK => "LLB"
    WORKER_UNDERTIME_HOURS => "WUH"
    WORKER_OVERTIME_HOURS => "WOH"
end

# Scoring
ScoringResult = @NamedTuple{penalty::Int, errors::Vector{Dict{String,Any}}}
ScoringResultOrPenalty = Union{ScoringResult,Int}

(+)(l::ScoringResult, r::ScoringResult) =
    ScoringResult((l.penalty + r.penalty, vcat(l.errors, r.errors)))

IntOrTuple = Union{Int,Tuple{Int,Int}}
IntOrNothing = Union{UInt8,Nothing}
MutationRecipe = @NamedTuple{
    type::Mutation.MutationEnum,
    day::Int,
    wrk_no::IntOrTuple,
    optional_info::IntOrNothing,
}

end

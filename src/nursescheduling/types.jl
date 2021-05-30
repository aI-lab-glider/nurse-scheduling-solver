# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# custom types used across the package

# Scoring
ScoringResult = @NamedTuple{penalty::Int, errors::Vector{Dict{String,Any}}}
ScoringResultOrPenalty = Union{ScoringResult,Int}

# Schedule related
Workers = Vector{String}
Shifts = Matrix{UInt8}
DayShifts = Vector{UInt8}
ScheduleShifts = Tuple{Workers,Shifts}

IntOrTuple = Union{Int,Tuple{Int,Int}}
IntOrNothing = Union{UInt8,Nothing}
MutationRecipe = @NamedTuple{
    type::Mutation.MutationEnum,
    day::Int,
    wrk_no::IntOrTuple,
    optional_info::IntOrNothing,
}

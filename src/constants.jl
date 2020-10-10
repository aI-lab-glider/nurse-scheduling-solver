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

# shift types
R = "R"    # morning (7-15)
P = "P"    # afternoon (15-19)
D = "D"    # daytime == R + P (7-19)
N = "N"    # night (19-7)
DN = "DN"  # day == D + N (7-7)
PN = "PN"  # afternoon-night == P + N (15-7)
W = "W"    # day free
U = "U"    # vacation
L4 = "L4"  # sick leave

CHANGEABLE_SHIFTS = [R, P, D, PN, N, DN]

SHIFTS_FULL_DAY = [D, DN]
SHIFTS_NIGHT = [PN, N, DN]
SHIFTS_MORNING = [R, D, DN]
SHIFTS_AFTERNOON = [P, D, PN, DN]

# decrease required worktime
SHIFTS_EXEMPT = [U, L4]
SHIFTS_TIME =
    Dict(R => 8, P => 4, D => 12, N => 12, DN => 24, PN => 16, W => 0, U => 0, L4 => 0)

REQ_CHLDN_PER_NRS_DAY = 3
REQ_CHLDN_PER_NRS_NIGHT = 5

DISALLOWED_SHIFTS_SEQS =
    Dict(N => [R, P, D, PN, DN], PN => CHANGEABLE_SHIFTS, DN => CHANGEABLE_SHIFTS)
# there has to be such a seq each week
LONG_BREAK_SEQ = (([U, L4, W], [N, U, L4, W]), ([R, P, D], [U, L4, W]))

# penalties
PEN_LACKING_NURSE = 40
PEN_LACKING_WORKER = 30
PEN_DISALLOWED_SHIFT_SEQ = 10
PEN_NO_LONG_BREAK = 20
# under and overtime pen is equal to hours from <0, MAX_OVERTIME>
MAX_OVERTIME = 10 # scaled by the number of weeks
MAX_UNDERTIME = 0 # scaled by the number of weeks

# weekly worktime
WORKTIME_BASE = 40

WEEK_DAYS_NO = 7
NUM_WORKING_DAYS = 5

@se TimeOfDay begin
    MORNING => "MORNING"
    AFTERNOON => "AFTERNOON"
    NIGHT => "NIGHT"
end

@se WorkerType begin
    NURSE => "NURSE"
    OTHER => "OTHER"
end

@se ErrorCode begin
    ALWAYS_AT_LEAST_ONE_NURSE => "AON"
    WORKERS_NO_DURING_DAY => "WND"
    WORKERS_NO_DURING_NIGHT => "WNN"
    DISALLOWED_SHIFT_SEQ => "DSS"
    LACKING_LONG_BREAK => "LLB"
    WORKER_UNDERTIME_HOURS => "WUH"
    WORKER_OVERTIME_HOURS => "WOH"
end

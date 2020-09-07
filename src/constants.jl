export R, P, D, N, DN, PN, W, U, L4,
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
    MAX_OVER_TIME,
    PEN_LACKING_NURSE,
    PEN_LACKING_WORKER,
    PEN_SHIFT_BREAK,
    PEN_DISALLOWED_SHIFT_SEQ,
    PEN_NO_LONG_BREAK,
    WORK_TIME,
    DAYS_OF_WEEK

# shift types
R = "R"    # rano (7-15)
P = "P"    # popołudnie (15-19)
D = "D"    # dzień == R + P (7-19)
N = "N"    # noc (19-7)
DN = "DN"  # doba == D + N (7-7)
PN = "PN"  # popołudnie-noc == P + N (15-7)
W = "W"    # wolne
U = "U"    # urlop
L4 = "L4"  # chorobowe

CHANGEABLE_SHIFTS = [R, P, D, PN, N, DN]

SHIFTS_FULL_DAY = [D, DN]
SHIFTS_NIGHT = [PN, N, DN]
SHIFTS_MORNING = [R, D, DN]
SHIFTS_AFTERNOON = [P, D, PN, DN]

SHIFTS_EXEMPT = [U, L4]
SHIFTS_TIME =
    Dict(R => 8, P => 4, D => 12, N => 12, DN => 24, PN => 16, W => 0, U => 0, L4 => 0)

REQ_CHLDN_PER_NRS_DAY = 3
REQ_CHLDN_PER_NRS_NIGHT = 5

DISALLOWED_SHIFTS_SEQS =
    Dict(N => [R, P, D, PN, DN], PN => CHANGEABLE_SHIFTS, DN => CHANGEABLE_SHIFTS)
# there has to be such a seq in each week
LONG_BREAK_SEQ = ([U, L4, W], [P, PN, N, U, L4, W])

# overtime stuff <- to be changed
MAX_OVER_TIME = 40

# penalties
PEN_LACKING_NURSE = 40
PEN_LACKING_WORKER = 30
PEN_DISALLOWED_SHIFT_SEQ = 10
PEN_NO_LONG_BREAK = 20
# under and overtime pen is equal to hours from <0, MAX_OVER_TIME>

# work time
WORK_TIME = Dict("FULL" => 40, "HALF" => 20)

# days of the week
MONDAY = "MO"
THUSDAY = "TU"
WEDNESDAY = "WE"
THURSDAY = "TH"
FRIDAY = "FR"
SATURDAY = "SA"
SUNDAY = "SU"

DAYS_OF_WEEK = [MONDAY, THUSDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY]

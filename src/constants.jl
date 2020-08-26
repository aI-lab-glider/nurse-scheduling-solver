# shift types
R = "R"    # rano (7-15)
P = "P"    # popołudnie (15-19)
D = "D"    # dzień == R + P (7-19)
N = "N"    # noc (19-7)
DN = "DN"  # doba == D + N (7-7)
PN = "PN"  # popołudnie-noc == P + N (15-7)
RPN = "RPN"# unused?
W = "W"    # wolne
U = "U"    # urlop
L4 = "L4"  # chorobowe

CHANGEABLE_SHIFTS = [R, P, D, PN, N, DN]

SHIFTS_FULL_DAY = [D, DN]
SHIFTS_NIGHT = [PN, N, DN]

SHIFTS_EXEMPT = [U, L4]
SHIFTS_TIME =
    Dict(R => 8, P => 4, D => 12, N => 12, DN => 24, PN => 16, W => 0, U => 0, L4 => 0)

REQ_CHLDN_PER_NRS_DAY = 3
REQ_CHLDN_PER_NRS_NIGHT = 5

DISALLOWED_SHIFTS_SEQS =
    Dict(N => [R, P, D, PN, DN], PN => CHANGEABLE_SHIFTS, DN => CHANGEABLE_SHIFTS)
# there has to be such a seq in each week
LONG_BREAK_SEQ = ([U, L4, W], [P, PN, N])

# overtime stuff <- to be changed
MAX_OVER_TIME = 40
MAX_STD = 10

# penalties
PEN_LACKING_NURSE = 1
PEN_SHIFT_BREAK = 1
PEN_DISALLOWED_SHIFT_SEQ = 1
PEN_NO_LONG_BREAK = 10

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

# shift types
R   = "R"  # rano (7-15)
P   = "P"  # popołudnie (15-22)
D   = "D"  # dzień == R + P (7-22)
N   = "N"  # noc (22-7)
DN  = "DN" # doba == D + N (7-7)
PN  = "PN" # unused for now
RPN = "RPN"# unused for now
W   = "W"  # wolne
U   = "U"  # urlop
L4  = "L4" # chorobowe

CHANGEABLE_SHIFTS = [R, P, D, N, DN]

# work time
FULL_TIME = "FULL"
PART_TIME = "HALF"

# days of the week
MONDAY    = "MO"
THUSDAY   = "TU"
WEDNESDAY = "WE"
THURSDAY  = "TH"
FRIDAY    = "FR"
SATURDAY  = "SA"
SUNDAY    = "SU"


# Scoring (penalting)

---

The result of scoring is a sum of the following three subscores:

- presence - the proper number of employees and nurses during a day,
- rights - controlling the amount of free time of each worker properly,
- working time - the magnitude of undertime and overtime of each employee.


## Constraints overview

- always at least one nurse
- at least one staff member for each three children during daytime
- at least one staff member for each five children during night
- only members of the same team can work simultaneously
- proper rest time between consecutive working shifts (24h, 16h and 11h)
- each worker has 35h off once a week (counted from MO to SU)
- undertime and overtime hours
- vacation and sick leave are untouchable (implicit constraint)

## Employees' presence

For each day, the solver evaluates the presence of all employees (workers and nurses) in the following way:

### Staff's presence:

1. the required number of employees during daytime equals to the number of children divided by three (the number of children per worker at daytime) minus the number of extra workers,
2. the required number of employees during night equals to the number of children divided by five (the number of children per worker at night),
3. the score is increased by the __PEN_LACKING_WORKER__ (default 40) multiplied by the number of employees lacking each hour.

### Nurses' presence:

1. it is evaluated if there is, at least, one nurse in each hour of a day,
2. the score is increased by the __PEN_LACKING_NURSE__ (default 50) multiplied by the number of hours with absence of a nurse.

### Teams's presence:

1. for each hour number of distinct teams is evaluated
2. the score is increased by the __PEN_MULTIPLE_TEAMS__ (default 20) multiplied by the number of teams for each hour.

## Employees’ rights

### Disallowed shift sequences

The algorithm evaluates succession of consecutive shifts to maintain a proper free time between working shifts of employees. The disallowed shift sequence is a two-element sequence stating the two working shifts cannot happen one after another. The sequences are determined by the duration and the ending hour first shift.

| Working shift duration (hours) | Required free time (hours) |
|:------------------------------:|:--------------------------:|
| <=8                            | 11                         |
| 9-12                           | 16                         |
| >=13                           | 24                         |

Each disallowed sequence in a schedule increases the score by  __PEN_DISALLOWED_SHIFT_SEQUENCE__ (default 10).

### Long breaks

Each employee must have at least one long break each week. It means a sequence of working and non-working shifts gives at least 35-hour uninterrupted free time. The long breaks are evaluated only from Monday to Sunday, the break between consecutive weeks does not value.

Each week lacking a long break for each employee increases the score by __PEN_NO_LONG_BREAK__ (default 20).

## Employees’ working time

The algorithm evaluates each employees’ working time in the following way:

1. the number of exempted days equals to the sum of holidays, sick leaves and other non-working shifts,
2. the required working time as the difference between the number of working days in a month and the exempted days multiplied by the number of hours an employee works per day (it results from employment or mandate contract),
3. the actual working time equals to the sum of worker's shift lengths.

If the difference between actual and required working time is larger than __MAX_OVERTIME__ (default 10) * days_in_month / 7, the score is increased by the difference between the overtime and the threshold.

If the difference between actual and required work time is smaller than __MAX_UNDERTIME__ (default 0) * days_in_month / 7, the total score is increased by the difference between the threshold and the undertime.

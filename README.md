# Nurse Scheduling Solver

The solver is part of the system created for [Fundacja Rodzin Adopcyjnych](https://adopcja.org.pl), the pre-adoption center in Warsaw (Poland). The project was set during Project Summer [AILab](http://www.ailab.agh.edu.pl) & [Glider](http://www.glider.agh.edu.pl) 2020 event and has been under intensive development since then.

The system aims to improve the operations of the foundation automatically, forming effective work schedules for employees. So far, this has been manually done in spreadsheets, which is a tedious job.

The migration to the system is realized by importing a plan from an Excel spreadsheet, which is the form, the foundation adopted earlier. If this is impossible, the application can be incorporated without previous schedules.

In the current version work plans are adjusted based on the legislation of Polish Labour Code for medical staff.

The system comprises three components which can be found on two GitHub repositories:
 - *web/desktop application* provides the environment for convenient preparation of work schedules (detailed information [here](https://github.com/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem-frontend))
 - *solver* responsible for finding issues in work schedules and fixing them automatically (not introduced yet)
 - *backend* ([Genie framework](https://genieframework.com/)) links the functions of both previous components

This repository contains the solver and the backend.

## Run solver

Required Julia version: `>=1.5`

1. Clone the project.

```bash
git clone https://github.com/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem-solver.git
```

2. Enter the project directory:

```bash
cd nurse-scheduling-problem-solver
```
3. Install dependencies

```bash
julia --project -E "using Pkg; Pkg.instantiate()"
```

4. Run server.

```bash
julia --project src/server.jl
```


## Frontend communication

### Server's endpoints

* POST `/fix_schedule`

  body - JSON - schedule

  response - JSON - repaired_schedule

* POST `/schedule_errors`

  body - JSON - schedule

  response - JSON - errors
  
### Finding issues

The broken constraints are tracked, and the information is passed to the frontend in a JSON list.

The table of error codes and their description:

|Constraints                    |Code|Other keys                                                                            |
|-------------------------------|:--:|--------------------------------------------------------------------------------------|
|Always at least one nurse      |AON | day::Int, segments::Vector{[segment_begin, segment_end]}                             |
|Workers number during daytime  |WND | day::Int, required::Int, actual::Int                                                 |
|Workers number during night    |WNN | day::Int, required::Int, actual::Int                                                 |
|Disallowed shift sequence      |DSS | day::Int, worker::String, preceding::Shift, succeeding::Shift                        |
|Lacking long break             |LLB | week::Int, worker::String                                                            |
|Worker undertime hours         |WUH | hours::Int, worker::String                                                           |
|Worker overtime hours          |WOH | hours::Int, worker::String                                                           |
|Worker teams collision         |WTC | day::Int, segments::Vector{[segment_begin, segment_end]}, teams::Vector{String}      |

The exemplary JSON list of the broken constraints:

```json
[
    {
      "code": "WND",
      "day": 7,
      "required": 4,
      "actual": 3
    },
    {
      "code": "LLB",
      "worker": "babysitter_7",
      "week": 1
    },
    {
      "code": "DSS",
      "day": 4,
      "worker": "nurse_4",
      "preceding": "DN",
      "succeeding": "P"
    }
]
```

### Shifts types

All shifts that should be recognized by the solver must be provided in the schedule's JSON under the __shift_types__ key:

```json
"shift_types": {
    "R": {
        "from": 7,
        "to": 15,
        "is_working_shift": true
    },
    "P": {
        "from": 15,
        "to": 19,
        "is_working_shift": true
    }, ...
}
```

The keys are shift codes and the values are dictionaries containing the following entries:

| Key              | Value                                       |
|------------------|---------------------------------------------|
| from             | Hour (1-24) when a shift begins             |
| to               | Hour (1-24) when a shift ends               |
| is_working_shift | Boolean value whether it is a working shift |


### Passing holidays

Occurrences of national holidays impact scoring due to the reduced number of working hours. The information about them can be passed in schedule JSON under the __month_info__ key as an array of day indices:

```json
"month_info": {
    "holidays": [7, 15, ...],
    ...
}
```

### Daytime/night handling

The start of daytime and night can be adjusted by providing the information in the input. Otherwise, the default configuration works (day starts at 6 and night at 22).

```JSON
"month_info": {
    "day_begin" : 6,
    "night_begin" : 22,
    ...
}
```

### Custom penalties

The process of automated fixing a schedule can be controlled in terms of removing particular issues before others. Each of the constraints has its weight (look at the table below). These with higher are considered as more important errors. The weights themselves can not be changed, but the priorities can by providing an ordered list of constraints' codes (from the highest priority to the lowest).

```json
"penalty_priorities" : [
    "AON",
    "WND",
    "WNN",
    "LLB",
    "DSS"
]
```
If priority code is not listed, the solver will set weight as 0 and will not return any errors related to that code.

| Penalty                         | Code | default weight |
|---------------------------------|------|:--------------:|
| Lacking nurse                   | AON  | 60             |
| Lacking worker during daytime   | WND  | 50             |
| Lacking worker during night     | WNN  | 40             |
| Lacking long break              | LLB  | 30             |
| Multiple working teams          | WTC  | 20             |
| Disallowed shift sequence       | DSS  | 10             |

---

## Scoring (penalting)

The result of scoring is a sum of the following three subscores:

- presence - the proper number of employees and nurses during a day,
- rights - controlling the amount of free time of each worker properly,
- working time - the magnitude of undertime and overtime of each employee.


### Constraints overview

- always at least one nurse
- at least one staff member for each three children during daytime
- at least one staff member for each five children during night
- only members of the same team can work simultaneously
- proper rest time between consecutive working shifts (24h, 16h and 11h)
- each worker has 35h off once a week (counted from MO to SU)
- undertime and overtime hours
- vacation and sick leave are untouchable (implicit constraint)

### Employees' presence

For each day, the solver evaluates the presence of all employees (workers and nurses) in the following way:

#### Staff's presence:

1. the required number of employees during daytime equals to the number of children divided by three (the number of children per worker at daytime) minus the number of extra workers,
2. the required number of employees during night equals to the number of children divided by five (the number of children per worker at night),
3. the score is increased by the __PEN_LACKING_WORKER__ (default 40) multiplied by the number of employees lacking each hour.

#### Nurses' presence:

1. it is evaluated if there is, at least, one nurse in each hour of a day,
2. the score is increased by the __PEN_LACKING_NURSE__ (default 50) multiplied by the number of hours with absence of a nurse.

#### Teams's presence:

1. for each hour number of distinct teams is evaluated
2. the score is increased by the __PEN_MULTIPLE_TEAMS__ (default 20) multiplied by the number of hours with multiple teams.

### Employees’ rights

#### Disallowed shift sequences

The algorithm evaluates succession of consecutive shifts to maintain a proper free time between working shifts of employees. The disallowed shift sequence is a two-element sequence stating the two working shifts cannot happen one after another. The sequences are determined by the duration and the ending hour first shift.

| Working shift duration (hours) | Required free time (hours) |
|:------------------------------:|:--------------------------:|
| <=8                            | 11                         |
| 9-12                           | 16                         |
| >=13                           | 24                         |

Each disallowed sequence in a schedule increases the score by  __PEN_DISALLOWED_SHIFT_SEQUENCE__ (default 10).

#### Long breaks

Each employee must have at least one long break each week. It means a sequence of working and non-working shifts gives at least 35-hour uninterrupted free time. The long breaks are evaluated only from Monday to Sunday, the break between consecutive weeks does not value.

Each week lacking a long break for each employee increases the score by __PEN_NO_LONG_BREAK__ (default 20).

### Employees’ working time

The algorithm evaluates each employees’ working time in the following way:

1. the number of exempted days equals to the sum of holidays, sick leaves and other non-working shifts,
2. the required working time as the difference between the number of working days in a month and the exempted days multiplied by the number of hours an employee works per day (it results from employment or mandate contract),
3. the actual working time equals to the sum of worker's shift lengths.

If the difference between actual and required working time is larger than __MAX_OVERTIME__ (default 10) * days_in_month / 7, the score is increased by the difference between the overtime and the threshold.

If the difference between actual and required work time is smaller than __MAX_UNDERTIME__ (default 0) * days_in_month / 7, the total score is increased by the difference between the threshold and the undertime.

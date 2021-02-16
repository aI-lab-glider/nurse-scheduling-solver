# Nurse Scheduling Problem Solver

The algorithm implementation is part of the solution created for [Fundacja Rodzin Adopcyjnych](https://adopcja.org.pl), the preadoption center in Warsaw (Poland). The project originated during Project Summer [AILab](http://www.ailab.agh.edu.pl) & [Glider](http://www.glider.agh.edu.pl) 2020 event and has been under intensive development since then.

The system aims to improve the foundation's operation by efficiently and quickly creating work schedules for its employees. So far, this has been done manually in spreadsheets, which is a tedious job.

The solution presented here is problem-specific. It assumes a particular form of input and output schedules, which the foundation adopted. The working plans themselves are adjusted based on the rules of the Polish Labour Code.

The system comprises three components, which can be found on two GitHub repositories:

 - *web/desktop* application, which provides an environment for convenient preparation of work schedules (detailed information [here](https://github.com/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem-frontend))
 - *solver*, responsible for finding issues in shift schedules and their automatic adjustment
 - *backend* ([Genie framework](https://genieframework.com/)), which allows for communication of both components

This repository contains the solver and the backend.

## Run the solver

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

### Endpoints

* POST `/fix_schedule`

  body - JSON - schedule

  response - JSON - repaired_schedule

* POST `/schedule_errors`

  body - JSON - schedule

  response - JSON - errors

## Constraints

 - always at least one nurse
 - during the day, at least one worker for each three children
 - during the night, at least one worker for each five children
 - after DN shift 24h off, after PN 16h and after the rest 11h
 - each worker has 35h off once a week (counted from MO to SU)
 - undertime and overtime hours
 - U and L4 untouchable (implicit constraint)

## Frontend communication

Broken constraints are tracked, and the information is passed to the frontend in a JSON list.

Table of error codes and their description:

|Constraints                    |Code|Other keys                                                     |
|-------------------------------|:--:|---------------------------------------------------------------|
|Always at least one nurse      |AON | day::Int, segments::(Vector{[segment_begin, segment_end]})    |
|Workers number during the day  |WND | day::Int, required::Int, actual::Int                          |
|Workers number during the night|WNN | day::Int, required::Int, actual::Int                          |
|Disallowed shift sequence      |DSS | day::Int, worker::String, preceding::Shift, succeeding::Shift |
|Lacking long break             |LLB | week::Int, worker::String                                     |
|Worker undertime hours         |WUH | hours::Int, worker::String                                    |
|Worker overtime hours          |WOH | hours::Int, worker::String                                    |

Exemplary JSON list of broken constraints:

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


## Shifts types

All shift available for the solver should be provided in the schedule's JSON under the _shift_types_ key:

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

Keys are shift codes and values are dictionaries containing the following entries:

| Key              | Value                                       |
|------------------|---------------------------------------------|
| from             | Hour (1-24) at which the shift begins       |
| to               | Hour (1-24) at which the shift ends         |
| is_working_shift | Boolean value whether it is a working shift |


### Passing holidays

Occurrences of national holidays impact scoring due to the reduced number of working hours. Information about them can be passed in schedule JSON under the _month_info_ key as an array of day indices:

```json
"month_info": {
    ...
    "holidays": [7, 15, ...],
    ...
}
```

## Day/night handling

The start of day and night can be adjusted by providing the information in the input. Otherwise, the default configuration is used (day starts at 6 and night at 22).

```JSON
 "month_info": {
    "day_begin" : 7,
    "night_begin" : 19,
    ...
  }
```

## Custom priorities

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
_All penalties must be listed, otherwise the schedule won't be accepted._

| Penalty                         | Code | default weight |
|---------------------------------|------|----------------|
| Lacking nurse                   | AON  | 50             |
| Lacking worker during the day   | WND  | 40             |
| Lacking worker during the night | WNN  | 30             |
| Lacking long break              | LLB  | 20             |
| Disallowed shift sequence       | DSS  | 10             |


---

## Scoring (penalting)

The result of scoring is a sum of the following three subscores:

- workers' presence - the proper number of employees and nurses during a day,
- workers' rights - workers must have at least one long break each week and the proper breaks after each working shift,
- workers' work time - the magnitude of undertime and overtime of each employee.

### Workers' presence

For each day, the solver evaluates the presence of all employees and nurses in the following way:

#### Workers' presence:

1. the required number of workers during the daytime equals to the number of children divided by three (the number of children per worker at daytime) minus the number of extra workers,

2. the required number of workers during the night equals to the number of children divided by five (the number of children per worker at night),

3. the score is increased by the ___PEN_LACKING_WORKER___ (default 40) multiplied by the number of workers lacking each hour.

#### Nurses presence:

1. the solver checks if there is at least one nurse in each hour of the day,

2. the score is increased by the ___PEN_LACKING_NURSE___ (default 50) multiplied by the number of hours which lacks a nurse.

### Workers rights

#### Disallowed shift sequences

The algorithm evaluates succession of consecutive shifts to maintain a proper free time between working shifts of employees. The disallowed shift sequence is a two-element sequence stating the two working shifts cannot happen one after another. The sequences are determined by the time the first shift lasts.

| Working shift lasting time (hours) | Required free time (hours) |
|:----------------------------------:|:--------------------------:|
| <=8                                | 8                          |
| 9-12                               | 16                         |
| >=13                               | 24                         |

For each such a sequence in a schedule, the algorithm increases the score by ___PEN_DISALLOWED_SHIFT_SEQUENCE___ (default 10).

#### Long breaks

Each worker must have at least one long break each week, meaning a sequence of working and non-working shifts giving at least 35-hour of uninterrupted free time. The long breaks are evaluated only from Monday to Sunday, the break between consecutive weeks does not value.

The algorithm applies ___PEN_NO_LONG_BREAK___ (default 20) for each week lacking a long break for each worker.

### Workers work time

The algorithm evaluates each worker's work time in the following way:

1. the number of exempted days equals to the sum of holidays, sick leaves and other not-working shifts,

2. the required work time as the difference between the number of working days in a month and the exempted days multiplied by the number of hours an employee work per day (it results from the employment or mandate contract),

3. the actual work time equals to the sum of worker's shifts lengths.

If the difference between actual and required work time is larger than ___MAX_OVERTIME___ (default 10) * days_in_month / 7, the score is increased by the difference between the overtime and the threshold.

If the difference between actual and required work time is smaller than ___MAX_UNDERTIME___ (default 0) * days_in_month / 7, the total score is increased by the difference between the threshold and the undertime.
# Nurse Scheduling Problem Solver

The algorithm implementation is a part of a solution created for [Fundacja Rodzin Adopcyjnych](https://adopcja.org.pl), the preadoption center in Warsaw (Poland). The project originated during Project Summer [AILab](http://www.ailab.agh.edu.pl) & [Glider](http://www.glider.agh.edu.pl) 2020 event and has been under intensive development since then.

The aim of the system is to improve the operation of the foundation by easily and quickly creating work schedules for its employees. So far, this has been done manually in spreadsheets which is a tedious job.

The solution presented here is problem-specific. It assumes a particular form of input and output schedules, which was adopted in the foundation for which the system is created. The schedules themselves are adjusted based on the rules of the Polish Labour Code.

The system consists of three components which are on two GitHub repositories:

 - web/desktop application which provides an environment for convenient preparation of work schedules (detailed information [here](https://github.com/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem-frontend))
 - solver written in Julia which can find issues in schedules and automatically fix them
 - backend written in Julia ([Genie framework](https://genieframework.com/)) which allows for communication of both aforementioned components

This repository contains the solver and the backend.

## Run the project

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
 - during the day at least one worker for each 3 children
 - during the night least one worker for each 5 children
 - after DN shift 24h off, after PN 16h and after the rest 11h
 - each worker has 35h off once a week (counted from MO to SU)
 - undertime and overtime hours
 - U and L4 untouchable (implicit constraint)

## Frontend communication

Broken constraints are tracked and the information is passed to front-end in a JSON list.

Table of error codes and their description:

|Constraints                    |Code|Other keys                                                     |
|-------------------------------|:--:|---------------------------------------------------------------|
|Always at least one nurse      |AON |day::Int, segments::(Vector{[segment_begin, segment_end]})     |
|Workers number during the day  |WND |day::Int, required::Int, actual::Int                           |
|Workers number during the night|WNN |day::Int, required::Int, actual::Int                           |
|Disallowed shift sequence      |DSS |day::Int, worker::String, preceding::Shifts, succeeding::Shifts|
|Lacking long break             |LLB |week::Int, worker::String                                      |
|Worker undertime hours         |WUH |hours::Int, worker::String                                     |
|Worker overtime hours          |WOH |hours::Int, worker::String                                     |

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

All shift available for the solver should be described provided in the schedule JSON under the _shift_types_ key:

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

Occurrences of national holidays impact scoring due to the reduced number of working hours. Information about them can be passed in schedule JSON under the _month_info_ key as an array of day indicies:

```json
"month_info": {
    ...
    "holidays": [7, 15, ...],
    ...
}
```

## Day/night handling

The start of day and night can be adjusted by providing the information in the input. Otherwise the default configuration is used (day starts at 6 and night at 22).

```JSON
 "month_info": {
    "day_begin" : 7,
    "night_begin" : 19,
    ...
  }
```

## Custom priorities

The process of automated fixing a schedule can be controlled in terms of removing particular issues before others. Each of constraints has its weight (look at table below), these with higher are considered as more important errors. The weights themselves can not be changed but solving priorities can by providing an ordered list of constraints' codes (from the highest priority to the lowest).
```json
    "penalty_priorities" : [
        "AON",
        "WND",
        "WNN",
        "LLB",
        "DSS"
    ]
```
_All penalties must be listed, otherwise schedule won't be accepted._

| Penalty                         | Code | default weight |
|---------------------------------|------|----------------|
| Lacking nurse                   | AON  | 50             |
| Lacking worker during the day   | WND  | 40             |
| Lacking worker during the night | WNN  | 30             |
| Lacking long break              | LLB  | 20             |
| Disallowed shift sequence       | DSS  | 10             |

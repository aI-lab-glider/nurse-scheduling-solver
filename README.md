# Nurse Scheduling Problem Solver

The algorithm implementation is a part of a solution created for [Fundacja Rodzin Adopcyjnych](https://adopcja.org.pl), the adoption foundation in Warsaw (Poland) during Project Summer [AILab](http://www.ailab.agh.edu.pl) & [Glider](http://www.glider.agh.edu.pl) 2020 event. The aim of the system is to improve the operation of the foundation by easily and quickly creating work schedules for its employees and volunteers. So far, this has been done manually in spreadsheets, which is a cumbersome and tedious job.

The solution presented here is problem-specific. It assumes a specific form of input and output schedules, which was adopted in the foundation for which the system is created. The schedules themselves are adjusted based on the rules of the Polish Labour Code.

The system consists of three components which are on two GitHub repositories:

 - web application which lets load a schedule and set its basic requirements (detailed information [here](https://github.com/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem-frontend))
 - solver written in Julia which adjusts schedules
 - backend also written in Julia ([Genie framework](https://genieframework.com/)) which allows for communication of both aforementioned components

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
3. Install dependecies

```bash
julia
julia> using Pkg
julia> Pkg.activate(".")
julia> Pkg.instantiate()
```
4. Run server.

```bash
julia --project=. src/server.jl
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
 - During the day at least one worker for each 3 children
 - During the night least one worker for each 5 children
 - after DN shift 24h off, after PN 16h and after the rest 11h
 - each worker has 35h off once a week (counted from MO to SU)
 - undertime and overtime hours
 - U and L4 untouchable (implicit constraint)

## Front-end communication

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

Sample JSON list of broken constraints:

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

All shift used in a given month, and additional available for solver should be described in the schedule JSON in _shift_types_ dict:

```json
    "shift_types" : {
      "R" : {
        "from" : 7,
        "to" : 15,
        "color" : "pink",
        "name" : "morning",
        "is_working_shift" : true
    }, 
      "P" : {
        "from" : 15,
        "to" : 19,
        "color" : "pink",
        "name" : "afternoon",
        "is_working_shift" : true
    }, ...
    }
```

Keys are shift codes, and values are dictionaries containing the following entries:

| Key              | Value                                    |
|------------------|------------------------------------------|
| from             | First hour of the shift                  |
| to               | First hour after the shift               |
| is_working_shift | Logic value whether the shift is working |


### Passing holidays

Occurrences of national holidays impact scoring due to the reduced number of working hours. Information about them can be passed in schedule JSON, in _month_info_ dictionary as a table of day indexes:

```json
    "month_info": {
        ...
        "holidays": [
            7, 15
        ],
        ...
    }
```

## Day/night handling

Beginning of the day and the night can be passed in the schedule JSON, in _month_info_ dictionary passing _day_begin_ and _night_begin_:

```JSON
 "month_info": {
    "day_begin" : 7,
    "night_begin" : 19,
    ...
  }    
```

## Custom priorities

Penalty priorities can be changed for a given schedule. They can be changes passing an ordered list of penalties (in descending order) in the main part of JSON as follows:
```json
    "penalty_priorities" : [
        "AON",
        "LLB",
        "DSS",
        "WND"
    ]
```
_(All penalties must be listed, otherwise schedule won't be accepted)_

Table of penalties, and their default weights:

| Penalty                         | Code | default weight |
|---------------------------------|------|----------------|
| Lacking nurse                   | AON  | 50             |
| Lacking worker during the day   | WND  | 40             |
| Lacking worker during the night | WNN  | 30             |
| Lacking long break              | LLB  | 20             |
| Disallowed shift sequence       | DSS  | 10             |

## Neighborhood generator

- only MutationRecipes are stored in Neighborhood

```julia
MutationRecipe = @NamedTuple{
    type::Mutation.MutationEnum,
    day::Int,
    wrk_no::IntOrTuple,
    op::StringOrNothing,
}
```
- full shifts (2d arrays) are generated on demand
- Neighborhood is immutable
- partial neighborhood can be generated by passing shifts which can not be changed


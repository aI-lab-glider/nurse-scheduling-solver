# Nurse Scheduling Problem Solver

The algorithm implementation is a part of solution created for the adoption foundation in Warsaw (Poland) during Project Summer AILab&Glider 2020 event. The aim of the system is to improve the operation of the foundation by easily and quickly creating work schedules for its employees and volunteers. So far, this has been done manually in spreadsheets, which is a cumbersome and tedious job.

The solution presented here is problem-specific. It assumes a specific form of input and output schedules, which was adopted in the adoption center for which the system is created. The schedules themselves are adjusted based on the rules of the Polish Labour Code.

The system consists of three components which are located in two GitHub repositories:

 - web application which lets load a schedule and set its basic requirements (more info [here](https://github.com/Project-Summer-AI-Lab-Glider/nurse-scheduling-problem))
 - a solver written in Julia which adjusts schedules
 - a back-end also in Julia (Genie framework) which allows for communication of both previous components

This repository contains the solver and the back-end.

## Supported shifts

|Shift code|Shift          |Work-time|Equivalent|
|:--------:|---------------|:-------:|:--------:|
|    R     |morning        |  7-15   |    -     |
|    P     |afternoon      |  15-19  |    -     |
|    D     |daytime        |  7-19   |  R + P   |
|    N     |night          |  19-7   |    -     |
|    DN    |day            |   7-7   |  D + N   |
|    PN    |afternoon-night|  15-7   |  P + N   |
|    W     |day free       |   N/A   |    -     |
|    U     |vacation       |   N/A   |    -     |
|    L4    |sick leave     |   N/A   |    -     |

## Constraints
 - always at least one nurse
 - from 6 to 22 at least one worker for each 3 children
 - from 22 to 6 at least one worker for each 5 children (doesn't have to be checked)
 - after DN shift 24h off, after PN 16h and after the rest 11h
 - each worker has 35h off once a week (checked from MO to SU)
 - undertime and overtime hours
 - U and L4 untouchable (implicit constraint)

## Front-end communucation

Broken constraints are tracked and the information is passed to front-end in a JSON list.

Table of error codes and their description:

|Constraints                    |Code|Other keys                                                     |
|-------------------------------|:--:|---------------------------------------------------------------|
|Always at least one nurse      |AON |day::Int, day_time::(“MORNING”&#124;”AFTERNOON”&#124;”NIGHT”)  |
|Workers number during the day  |WND |day::Int, required::Int, actual::Int                           |
|Workers number during the night|WNN |day::Int, required::Int, actual::Int                           |
|A disallowed shift sequence    |DSS |day::Int, worker::String, preceding::Shifts, succeeding::Shifts|
|A lacking long break           |LLB |week::Int, worker::String                                      |
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
- full shifts (2d array) are generated on demand
- Neighborhood is randomized on initialization
- Neighborhood is immutable


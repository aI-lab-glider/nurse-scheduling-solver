# Nurse Scheduling Problem Algorithm

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

Broken constraints are tracked and the infromation is passed to front-end in a JSON list.

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

A sample broken constraints JSON list:

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
- Neighborhood is randomized on its initialization
- Neighborhood is immutable


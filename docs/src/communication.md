# Frontend communication

---

## Server's endpoints

* POST `/fix_schedule`

  body - JSON - schedule

  response - JSON - repaired_schedule

* POST `/schedule_errors`

  body - JSON - schedule

  response - JSON - errors
  
## Finding issues

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
|Worker teams collision         |WTC | day::Int, hour::Int, workers::Vector{String}                                         |

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

## Shifts types

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


## Passing holidays

Occurrences of national holidays impact scoring due to the reduced number of working hours. The information about them can be passed in schedule JSON under the __month_info__ key as an array of day indices:

```json
"month_info": {
    "holidays": [7, 15, ...],
    ...
}
```

## Daytime/night handling

The start of daytime and night can be adjusted by providing the information in the input. Otherwise, the default configuration works (day starts at 6 and night at 22).

```JSON
"month_info": {
    "day_begin" : 6,
    "night_begin" : 22,
    ...
}
```

## Workers' teams

Teams are passed in the _team_ dictionary inside the ___employee_info___. If such is not provided, the algorithm will not evaluate teams collisions.
```JSON
  "employee_info": {
      ...
        "team": {
            "nurse_1":  "NURSE",
            "nurse_2":  "NURSE",
            "babysitter_1": "OTHER",
            "babysitter_2": "OTHER"
        },
      ...
```

## Custom penalties

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
| Worker teams collision          | WTC  | 20             |
| Disallowed shift sequence       | DSS  | 10             |
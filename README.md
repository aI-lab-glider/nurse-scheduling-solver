# Nurse Scheduling Problem Algorithm

TODO:
 - TabuSearch

Done in the latest sprint:
 - created a user for backend on my server (0.5h)
 - new constraint (2h):
    - check nurse presence during the day
    - differentiation between nurses and other workers
    - a lacking nurse 40 points penalty
 - scoring module improvement (3h):
    - renamed module and file
    - there are no soft constraints anymore
    - new penalties:
        - a lacking worker 30 points each
        - a lacking long break 20 points each week
        - a disallowed shift seq 10 points each
        - MAX_OVER_TIME == 40, MAX_STD removed
        - over and undertime penalty is equal to the distance from <0, MAX_OVER_TIME>
    - fixed bug in long breaks checking
    - general code refactor
 - broken constrains info in Julia Dicts (3h):
    - table of error codes and msg descs
 
|Constraints                    |Code|Other keys                                                     |
|-------------------------------|:--:|---------------------------------------------------------------|
|Always at least one nurse      |AON |day::Int, day_time::(“MORNING”&#124;”AFTERNOON”&#124;”NIGHT”)  |
|Workers number during the day  |WND |day::Int, required::Int, actual::Int                           |
|Workers number during the night|WNN |day::Int, required::Int, actual::Int                           |
|A disallowed shift sequence    |DSS |day::Int, worker::String, preceding::Shifts, succeeding::Shifts|
|A lacking long break           |LLB |week::Int, worker::String                                      |
|Worker undertime hours         |WUH |hours::Int, worker::String                                     |
|Worker overtime hours          |WOH |hours::Int, worker::String                                     |

Constraints:
 - always at least one nurse
 - from 6 to 22 at least one worker for each 3 children
 - from 22 to 6 at least one worker for each 5 children (doesn't have to be checked)
 - after DN shift 24h off, after PN 16h and after the rest 11h
 - each worker has 35h off once a week (checked from MO to SU)
 - undertime and overtime hours
 - U and L4 untouchable (implicit constraint)

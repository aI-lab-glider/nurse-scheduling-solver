# Nurse Scheduling Problem Algorithm

Done in the latest sprint:
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
    - general refactor

TODO:
 - TabuSearch
 - JSON logging, but no by logs
 - preparing server for backend

Constraints:
 - always at least one nurse
 - from 6 to 22 at least one nurse for each 3 children
 - from 22 to 6 at least one nurse for each 5 children (doesn't have to be checked)
 - after DN shift 24h off, after PN 16h and after the rest 11h
 - each worker has 35h off once a week (checked from MO to SU)
 - U and L4 untouchable (implicit constraint)
 - undertime and overtime (soft constraint)

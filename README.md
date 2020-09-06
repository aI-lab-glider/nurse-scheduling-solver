# Nurse Scheduling Problem Algorithm

Done in the latest sprint:
 - scoring improvement (3h):
    - there are no soft constraints anymore
    - new penalties:
        - lacking nurses 30 points each
        - lacking a long break 20 points each week
        - a disallowed shift seq 10 points each
        - MAX_OVER_TIME == 40, MAX_STD removed
        - over and undertime penalty is equal to the distance from <0, MAX_OVER_TIME>
    - fixed bug in long breaks checking

TODO:
 - differentiation between types of employees (new constraint)
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

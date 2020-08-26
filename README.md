# Nurse Scheduling Problem Algorithm

### Mini plan


Done in the latest sprint:
 - the size of the max neighborhood can be evaluated for a schedule
 - fitness function evaluates constraints and outputs score
 - debug mode can be used to inform which and where in a schedule constraints are broken

TODO:
 - neighborhood can be generated partially utilizing generator
 - the app is a CLI program and can be run with different arguments

constraints:
 - always at least one nurse (not applicable yet)

 - from 6 to 22 at least one nurse for each 3 children
 - from 22 to 6 at least one nurse for each 5 children
 - after DN shift 24h off, after the rest 11h off
 - each worker has 35h off once a week
 - U and L4 untouchable (implicit constraint)
 - overtime (soft constraint)

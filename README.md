# Nurse Scheduling Problem Algorithm

Done in the latest spring:
 - neighborhood is an iterable
 - fixed neiborhood generation and other minor bugs

TODO:
 - the app is a CLI program and can be run with different arguments

Done previously:
 - the size of the max neighborhood can be evaluated for a schedule
 - fitness function evaluates constraints and outputs score
 - debug mode can be used to inform which and where in a schedule constraints are broken

Constraints:
 - always at least one nurse (not applicable yet)

 - from 6 to 22 at least one nurse for each 3 children
 - from 22 to 6 at least one nurse for each 5 children
 - after DN shift 24h off, after PN 16h and after the rest 11h
 - each worker has 35h off once a week (checked from MO to SU)
 - U and L4 untouchable (implicit constraint)
 - overtime (soft constraint)

using Pkg
Pkg.activate(".")
Pkg.instantiate()

file = "schedules/schedule_2016_august_medium.json"

include("old_engine/NurseScheduling.jl")
include("../src/repair_schedule.jl")

function repair!(schedule)
    fix = repair_schedule(schedule.data)
    update_shifts!(schedule, fix)
end


schedule = Schedule(file)


redirect_stdout(open("/dev/null", "w")) do
    repair!(schedule)
end


errors = OldNurseSchedules.get_errors(schedule.data)

if errors == []
    println("TEST PASSED")
else
    pritnln("TEST FAILED")
    println("Errors found by old engine: '$errors'")
end
include("old_engine/NurseScheduling.jl")
include("../src/repair_schedule.jl")

new_errors = get_errors("schedules/schedule_2016_august_medium.json")

old_errors = OldNurseSchedules.get_errors("schedules/schedule_2016_august_medium.json")
test_flag = true


for old_error in old_errors
    new_error = new_errors[1]
    if old_error != "AON"
        if old_error == new_error
            deleteat!(new_errors, 1)
        else
            test_flag = false
            println("Scoring error: OLD: '$old_error', NEW: '$new_error'")
        end
    else
        if old_error["day"] == new_error["day"]
            deleteat!(new_errors, 1)
        else
            test_flag = false
            println("Scoring error: OLD: '$old_error', NEW: '$new_error'")
        end
    end
end

if test_flag
    println("TEST PASSED")
else
    println("TEST FAILED")
end
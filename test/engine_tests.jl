include("old_engine/NurseScheduling.jl")
include("../src/repair_schedule.jl")

using Test
using .NurseSchedules:
    Schedule,
    get_disallowed_sequences

function repair!(schedule)
    fix = repair_schedule(schedule.data)
    update_shifts!(schedule, fix)
end

function solve(file)
    schedule = Schedule(file)
    redirect_stdout(open("/dev/null", "w")) do
        repair!(schedule)
    end
    schedule.data
end

function check_errors(file)
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
            end
        else
            if old_error["day"] == new_error["day"]
                deleteat!(new_errors, 1)
            else
                test_flag = false
            end
        end
    end
    test_flag
end

function compare_dss(old, new)
    for (key, table) in new
        if table != [] && sort(old[key]) != sort(table)
            return false
        end
    end
    true
end

function get_new_dss()
    get_disallowed_sequences(Schedule("schedules/schedule_2016_august.json"))
end

@testset "Check new solutions" begin
    @test [] == OldNurseSchedules.get_errors(solve("schedules/schedule_2016_august_medium.json"))
end

@testset "Compare errors" begin
    @test check_errors("schedules/schedule_2016_august_extended.json")
    @test check_errors("schedules/schedule_2016_august_frontend.json")
    @test check_errors("schedules/schedule_2016_august_medium.json")
    @test check_errors("schedules/schedule_2016_august_unsolvable.json")
    @test check_errors("schedules/schedule_2016_august.json")
end

@testset "Disallowed shift sequences" begin
    @test compare_dss(OldNurseSchedules.DISALLOWED_SHIFTS_SEQS, get_new_dss())
end
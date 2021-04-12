# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

cd("../")

include("old_engine/NurseScheduling.jl")
include("../src/repair_schedule.jl")

using Test
using .NurseSchedules:
    Schedule,
    get_disallowed_sequences,
    get_next_day_distance,
    get_earliest_shift_begin,
    get_latest_shift_end,
    sum_segments

function repair!(schedule::Schedule)
    fix = repair_schedule(schedule.data)
    update_shifts!(schedule, fix)
end

function solve(file::String)
    schedule = Schedule(file::String)
    redirect_stdout(open("/dev/null", "w")) do
        repair!(schedule)
    end
    schedule.data
end

function get_errors_sets(file::String)::Tuple{Set, Set}
    new_errors = get_errors(file)
    old_errors = OldNurseSchedules.get_errors(file)
    old_errors = Set(vcat(
        # Pass non AON errors
        filter(x -> x["code"] != "AON", old_errors),
        # Leave only one error for each day from AON, and drop other metadata
        map(x -> delete!(x, "time_of_day"),
            unique(x -> x["day"], 
                filter(x -> x["code"] == "AON", old_errors
        )))
    ))
    new_errors = Set(vcat(
        # Pass non AON errors
        filter(x -> !(x["code"] in ["AON", "WNN", "WND"]), new_errors),
        # Drop segments from AON, WNN and WND
        map(x -> delete!(x, "segments"),
            filter(x -> x["code"] in ["AON", "WNN", "WND"], new_errors
        ))
    ))
    old_errors, new_errors
end

function check_single_type_errors(code::String, file::String)
    old_errors, new_errors = get_errors_sets(file)
    old = filter(x -> x["code"] == code, old_errors) 
    new = filter(x -> x["code"] == code, new_errors)
    if old == new
        true
    else
        @info "Different errors for type and file: " code file 
        @info "Old \\ New " setdiff(old, new)
        @info "New \\ Old " setdiff(new, old)
        @info ""
        false
    end
end

ShiftSequence = Dict{String, Array{String, 1}}
function compare_dss(old::ShiftSequence, new::ShiftSequence)
    for (key, table) in new
        if !isempty(table) && sort(old[key]) != sort(table)
            @info "Different sequences for key: " key
            @info "Old sequence " old[key]
            @info "New sequence " table
            return false
        end
    end
    true
end

function get_new_dss()
    get_disallowed_sequences(Schedule("schedules/schedule_2016_august_medium.json"))
end

@testset "Compare errors" begin
    error_types = ["WND", "WNN", "AON", "DSS", "LLB"]
    test_sets = [
        "schedules/schedule_2016_august_extended.json",
        "schedules/schedule_2016_august_frontend.json",
        "schedules/schedule_2016_august_medium.json",
        "schedules/schedule_2016_august_unsolvable.json",
        "schedules/schedule_2016_august.json"
    ]
    @testset "Compare $type" for type in error_types
        for test_set in test_sets
            @test check_single_type_errors(type, test_set)
        end
    end
end

@testset "Disallowed shift sequences" begin
    @test compare_dss(OldNurseSchedules.DISALLOWED_SHIFTS_SEQS, get_new_dss())
end

@testset "Schedule tests" begin
    schedule = Schedule("schedules/schedule_2016_august_medium.json")
    @test get_earliest_shift_begin(schedule) == 7
    @test get_latest_shift_end(schedule) == 31
end

@testset "Custom penalties tests" begin
    applied_errors = ["WNN", "WND", "LLB", "DSS"]
    schedule = "schedules/schedule_2016_august_custom.json"
    new_errors = get_errors(schedule)
    @test isempty(filter(x -> x["code"] == "AON", new_errors))
    for err_type in applied_errors
        @test check_single_type_errors(err_type, schedule)
    end
end

@testset "Shifts.jl tests" begin
    @testset "Next day shift distance" begin
        # X entry doesn't have any meaning, just forces Dict{String, Any} type
        x = Dict(
            "from" => 12,
            "to" => 18,
            "x" => "y"
        )
        y = Dict(
            "from" => 20,
            "to" => 6,
            "x" => "y"
        )
        z = Dict(
            "from" => 2,
            "to" => 8,
            "x" => "y"
        )
        @test get_next_day_distance(x, y) == 26
        @test get_next_day_distance(x, z) == 8 
        @test get_next_day_distance(y, x) == 6
        @test get_next_day_distance(y, z) == -4
        @test get_next_day_distance(z, x) == 28
        @test get_next_day_distance(z, y) == 36
    end

    @testset "Segments sum tests" begin
        segments = [
            (1, 3),
            (6, 8)
        ]
        @test sum_segments(segments) == 4
        push!(segments, (22, 2))
        @test sum_segments(segments) == 8
    end
end
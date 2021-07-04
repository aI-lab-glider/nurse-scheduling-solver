# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
using NurseSchedulingSolver.Model:
    Schedule,
    base_shifts,
    actual_shifts,
    decode_shifts,
    employee_uuid,
    employee_shifts,
    employee_base_shifts,
    employee_actual_shifts

using NurseSchedulingSolver.Model.schedule: _make_shift_coding, BasicShift, DEFAULT_SHIFTS

SCHEDULE_PATH = "schedules/2016_august_medium_new_form.json"

@testset "Parse schedule from JSON" begin
    #TODO make sure that all jsons in the schedule dir are parsable and valid

    schedule1 = Schedule(SCHEDULE_PATH)

    @test true
end

@testset "Schedule coding" begin
    @testset "Create shift coding" begin
        shift_coding = _make_shift_coding([])
        basic_shift_count = length(instances(BasicShift.BasicShiftEnum))
        @test length(shift_coding) == basic_shift_count

        custom_shift_count = length(DEFAULT_SHIFTS)
        shift_coding = _make_shift_coding(DEFAULT_SHIFTS)
        @test length(shift_coding) == basic_shift_count + custom_shift_count
        @test values(shift_coding) |> unique |> length == length(shift_coding)

        #TODO test against all our schedules
        schedule = Schedule(SCHEDULE_PATH)
        shift_coding = _make_shift_coding(schedule.meta["available_shifts"])
        @testset "Schedule: $(basename(SCHEDULE_PATH))" begin
            @test values(shift_coding) |> unique |> length == length(shift_coding)
        end
    end

    @testset "Shifts coding" begin
        schedule = Schedule(SCHEDULE_PATH)

        @testset "Convert shifts to the UInt8 representation" begin
            @test typeof(base_shifts(schedule)) == Matrix{UInt8}
            @test typeof(actual_shifts(schedule)) == Matrix{UInt8}
        end

        @testset "Convert shifts back to the string representation" begin
            shifts = base_shifts(schedule)
            decoded_shifts = decode_shifts(schedule, shifts)
            @test typeof(decoded_shifts) == Matrix{String}

            for e_no in axes(decoded_shifts, 1)
                @test decoded_shifts[e_no, :] == employee_base_shifts(schedule, e_no)
            end
        end

    end
end

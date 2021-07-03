# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

using NurseSchedulingSolver.Model: Schedule
using NurseSchedulingSolver.Model.schedule: _map_shift_codes, BasicShift, DEFAULT_SHIFTS


@testset "Parse schedule from JSON" begin
    #TODO all jsons in dir schedule should be tested

    schedule = Schedule("schedules/2016_august_medium_new_form.json")
    @test true
end

@testset "Map shift codes to UInt8" begin
    shift_codes = _map_shift_codes([])
    basic_shift_count = length(instances(BasicShift.BasicShiftEnum))
    @test length(shift_codes) == basic_shift_count

    custom_shift_count = length(DEFAULT_SHIFTS)
    shift_codes = _map_shift_codes(DEFAULT_SHIFTS)
    @test length(shift_codes) == basic_shift_count + custom_shift_count
end

# @testset "update_shifts!" begin
#     schedule1 = Schedule("schedules/schedule_2016_august_medium.json")
#     (workers, shifts) = get_shifts(schedule1)
#     @test schedule1.data["shifts"][workers[1]][1] != W
#     shifts[1, 1] = W_ID
#     update_shifts!(schedule1, shifts)
#     @test schedule1.data != Schedule("schedules/schedule_2016_august_medium.json")
#     @test schedule1.data["shifts"][workers[1]][1] == W
# end

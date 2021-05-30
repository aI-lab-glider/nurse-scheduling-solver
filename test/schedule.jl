# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

@testset "update_shifts!" begin
    schedule1 = Schedule("schedules/schedule_2016_august_medium.json")
    (workers, shifts) = get_shifts(schedule1)
    @test schedule1.data["shifts"][workers[1]][1] != W
    shifts[1, 1] = W_ID
    update_shifts!(schedule1, shifts)
    @test schedule1.data != Schedule("schedules/schedule_2016_august_medium.json")
    @test schedule1.data["shifts"][workers[1]][1] == W
end
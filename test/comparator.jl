# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

include("../src/scoring.jl")

using .ScheduleScoring:
    ck_workers_worktime

using .NurseSchedules:
    cmp_workers_worktime

function check(schedule, old, new; info=false)
    l = cmp_workers_worktime(old, new, schedule)
    r = ck_workers_worktime(new, schedule)
    
    if l.penalty != r.penalty || keys(l.errors) != keys(r.errors)
        if info
            @info "Different penalties: " l.penalty, r.penalty
            @info "CMP \\ CK " setdiff(keys(l.errors), keys(r.errors))
            @info "CK \\ CMP " setdiff(keys(r.errors), keys(l.errors))
        end
        false
    else
        if info
            @info "Received score: " l.penalty
        end
        true
    end
end

@testset "Basic cmp_workers_worktime case" begin
    base = Schedule("schedules/schedule_2016_august_medium.json")
    working_type = base.shift_map["PN"]

    base_s = get_shifts(base)
    working_s = (base_s[1], fill(working_type, size(base_s[2])))

    @test check(base, base_s, base_s ) == false
    @test check(base, working_s, base_s, info=true) == true 
end
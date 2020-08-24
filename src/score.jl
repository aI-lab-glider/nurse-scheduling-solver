module ScheduleScore

using ..NurseSchedules

export score

function score(schedule::Schedule)::Int
    get_shifts(schedule)
    42
end

end # ScheduleScore

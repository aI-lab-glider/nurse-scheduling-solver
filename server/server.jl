using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests
using HTTP
include("../src/NursesScheduling.jl")
using .NurseSchedules
using .NurseSchedules: Shifts


include("../src/repair_schedule.jl")
include("../src/get_errors.jl")

route("/repaired_schedule", method = POST) do
    schedule = jsonpayload()

    repaired_schedule = repair_schedule(schedule)

    repaired_schedule |> json
end

route("/schedule_errors", method = POST) do
    schedule = jsonpayload()

    errors = get_errors(schedule)

    errors |> json
end

Genie.startup(async = false)

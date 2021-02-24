# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests
using HTTP
include("repair_schedule.jl")
include("logger.jl")

using .Logger

Genie.config.run_as_server = true
Genie.config.server_host = "0.0.0.0"
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "POST, OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

route("/fix_schedule", method = POST) do
    schedule_data = jsonpayload()

    request_name = get_request_name()
    save_schedule(schedule_data, request_name)
    @info "Received request '$request_name'"

    try
        repaired_shifts = repair_schedule(schedule_data)
        schedule = Schedule(schedule_data)
        update_shifts!(schedule, repaired_shifts)
        flush_logs()
        schedule.data |> json
    catch err
        @error "Unexpected error at fix schedule : " err.msg
        @error "Schedule ID: " log_id
        @error "Backtrace: " catch_backtrace() 
        flush_logs()
        Dict() |> json
    end
end

route("/schedule_errors", method = POST) do
    schedule_data = jsonpayload()

    request_name = get_request_name()
    save_schedule(schedule_data, request_name)
    @info "Received request '$request_name'"

    try
        errors = get_errors(schedule_data)
        flush_logs()
        errors |> json
    catch err
        @error "Unexpected error at schedule errors : " err.msg
        @error "Schedule ID: " log_id
        @error "Backtrace: " catch_backtrace()
        flush_logs()
        Dict() |> json
    end
end

Genie.startup(async = false)

module JsonValidator

using JSON

schedule = JSON.parsefile("schedules/schedule_2016_august.json")
JSON.print(schedule["month_info"]["month_number"], 4)

end # JsonValidator
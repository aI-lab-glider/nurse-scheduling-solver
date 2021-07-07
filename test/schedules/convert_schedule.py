#!/usr/bin/env python3
import json
import argparse

parser = argparse.ArgumentParser(
    description="Convert an old schedule file to the new structure."
)
parser.add_argument("filepath", type=str, help="Path to the schedule file.")
parser.add_argument(
    "-n",
    "--nono",
    action="store_true",
    help="Print reformated file to stdout instead of overwriting a file",
)
args = parser.parse_args()

with open(args.filepath) as f:
    schedule = json.load(f)


new_schedule = dict()
new_schedule["employees"] = list()

for uuid, time in schedule["employee_info"]["time"].items():
    new_schedule["employees"].append(
        {"uuid": uuid, "working_time": time, "contract_type": "EMPLOYMENT"}
    )

for uuid, employee_type in schedule["employee_info"]["type"].items():
    employees = new_schedule["employees"]
    employee_obj = next(filter(lambda x: x["uuid"] == uuid, employees), None)
    if employee_obj is not None:
        employee_obj["type"] = employee_type

for uuid, shifts in schedule["shifts"].items():
    employee_obj = next(filter(lambda x: x["uuid"] == uuid, employees), None)
    if employee_obj is not None:
        employee_obj["base_shifts"] = shifts
        employee_obj["actual_shifts"] = shifts

new_schedule["available_shifts"] = list()
for shift_code, meta in schedule["shift_types"].items():
    new_shift = {
        "code": shift_code,
        "type": "WORKING" if meta["is_working_shift"] else "NON-WORKING",
    }
    if new_shift["type"] == "WORKING":
        new_shift["from"] = meta["from"]
        new_shift["to"] = meta["to"]

    new_schedule["available_shifts"].append(new_shift)

new_schedule["month_meta"] = list()
for i, children_number in enumerate(schedule["month_info"]["children_number"]):
    month_info = schedule["month_info"]
    new_schedule["month_meta"].append(
        {
            "children": children_number,
            "extra_workers": month_info["extra_workers"][i],
            "is_frozen": i + 1 in month_info["frozen_shifts"],
            "is_holiday": i + 1 in month_info["holidays"],
            "day_of_month": i - 30 if i > 30 else i + 1,
            "day_of_week": i % 7 + 1,
        }
    )

new_schedule["settings"] = {
    "daytime_begin": schedule["month_info"]["day_begin"],
    "night_begin": schedule["month_info"]["night_begin"],
}

if args.nono:
    print(json.dumps(new_schedule, indent=4))
else:
    with open(args.filepath, "w") as f:
        json.dump(new_schedule, f, indent=4)

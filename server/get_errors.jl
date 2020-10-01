function get_errors(schedule_data)

    nurse_schedule = Schedule(schedule_data)

    schedule_shifts = get_shifts(nurse_schedule)
    month_info = get_month_info(nurse_schedule)
    workers_info = get_workers_info(nurse_schedule)

    _, errors = score(schedule_shifts, month_info, workers_info, true)
    return errors
end

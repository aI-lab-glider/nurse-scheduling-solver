module Neighborhood

export get_nbhd, get_max_nbhd_size

using ..NurseSchedules: Schedule, get_shifts, CHANGEABLE_SHIFTS, W

function get_max_nbhd_size(schedule::Schedule)::Int
    shifts = get_shifts(schedule)

    from_addtition = count(s -> (s == W), shifts) * length(CHANGEABLE_SHIFTS)
    @debug "Neighbors number from addition: $from_addtition"
    from_deletion = count(s -> (s in CHANGEABLE_SHIFTS), shifts)
    @debug "Neighbors number from deletion: $from_deletion"

    from_swap = sum([
        1
        for
        person in CartesianIndices(shifts),
        o_person in CartesianIndices(shifts) if
        person[1] != o_person[1] &&
        person < o_person &&
        shifts[person] != shifts[o_person] &&
        shifts[person] in CHANGEABLE_SHIFTS &&
        shifts[o_person] in CHANGEABLE_SHIFTS
    ])
    @debug "Neighbors number from swap: $from_swap"

    return from_addtition + from_deletion + from_swap
end

function get_nbhd(schedule::Schedule)
    neighborhood = Array{String,2}[]
    shifts = get_shifts(schedule)

    for person_shift in CartesianIndices(shifts)
        mutated_schedules = if shifts[person_shift] == W
            with_shift_addtion(shifts, person_shift)
        elseif shifts[person_shift] in CHANGEABLE_SHIFTS
            vcat(
                with_shift_deletion(shifts, person_shift),
                with_shift_swap(shifts, person_shift),
            )
        else
            []
        end
        append!(neighborhood, mutated_schedules)
    end
    return neighborhood
end


function with_shift_addtion(shifts::Array{String,2}, person_shift)::Array{Array{String,2}}
    mutated_schedules = Array{String,2}[]

    for allowed_shift in CHANGEABLE_SHIFTS
        mutated_schedule = copy(shifts)
        mutated_schedule[person_shift] = allowed_shift
        push!(mutated_schedules, mutated_schedule)
    end
    return mutated_schedules
end

function with_shift_deletion(shifts::Array{String,2}, person_shift)::Array{Array{String,2}}
    mutated_schedule = copy(shifts)
    mutated_schedule[person_shift] = W
    return [mutated_schedule]
end

function with_shift_swap(shifts::Array{String,2}, person)::Array{Array{String,2}}
    mutated_schedules = Array{String,2}[]

    for o_person in CartesianIndices(shifts)
        if person[1] != o_person[1] &&
           person < o_person &&
           shifts[person] != shifts[o_person] &&
           shifts[person] in CHANGEABLE_SHIFTS &&
           shifts[o_person] in CHANGEABLE_SHIFTS

            mutated_schedule = copy(shifts)
            mutated_schedule[person], mutated_schedule[o_person] =
                mutated_schedule[o_person], mutated_schedule[person]

            push!(mutated_schedules, mutated_schedule)
        end
    end
    return mutated_schedules
end

end # Neighborhood

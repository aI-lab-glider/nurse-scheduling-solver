module NeighborhoodGen

export Neighborhood, get_max_nbhd_size

using Random
using ..NurseSchedules:
    Schedule, Shifts, get_shifts, W, CHANGEABLE_SHIFTS, Mutation, MutationRecipe

import Base: length, iterate, getindex, in

function get_max_nbhd_size(schedule::Schedule)::Int
    _, shifts = get_shifts(schedule)

    from_addtition = count(s -> (s == W), shifts) * length(CHANGEABLE_SHIFTS)
    @debug "Neighbors number from addition: $from_addtition"
    from_deletion = count(s -> (s in CHANGEABLE_SHIFTS), shifts)
    @debug "Neighbors number from deletion: $from_deletion"
    from_swap = sum([
        1
        for # shift = (worker_no, day_no)
        shift in CartesianIndices(shifts),
        o_shift in CartesianIndices(shifts) if
        shifts[shift] != shifts[o_shift] &&
        shift[2] == o_shift[2] &&
        shift < o_shift &&
        shifts[shift] in CHANGEABLE_SHIFTS &&
        shifts[o_shift] in CHANGEABLE_SHIFTS
    ])
    @debug "Neighbors number from swap: $from_swap"

    return from_addtition + from_deletion + from_swap
end

struct Neighborhood
    mutation_recipes::Vector{MutationRecipe}
    shifts::Shifts

    function Neighborhood(shifts::Shifts)
        mutation_recipes = get_nbhd(shifts)
        shuffle!(mutation_recipes)
        new(mutation_recipes, shifts)
    end

    function Neighborhood(shifts::Shifts, frozen_days::Vector{Int})
        mutation_recipes = get_nbhd(shifts)
        allowed_recipies = filter(recipe -> !(recipe.day in frozen_days), mutation_recipes)
        shuffle!(allowed_recipies)
        new(allowed_recipies, shifts)
    end

    function Neighborhood(shifts::Shifts, frozen_shifts::Vector{Tuple{Int,Int}})
        mutation_recipes = get_nbhd(shifts)
        days = frozen_days
        allowed_recipies = filter(recipe -> !(recipe in frozen_shifts), mutation_recipes)
        shuffle!(mutation_recipes)
        new(mutation_recipes, shifts)
    end
end

function in(recipe::MutationRecipe, frozen_shifts::Vector{Tuple{Int,Int}})
    for (worker_no, day) in frozen_shifts
        if recipe.day == day && recipe.wrk_no in worker_no
            return true
        end
    end
    false
end

length(nbhd::Neighborhood) = length(nbhd.mutation_recipes)

getindex(nbhd::Neighborhood, idx::Int) = recipe_consumer(nbhd, idx)

function iterate(nbhd::Neighborhood)
    return recipe_consumer(nbhd, nbhd.mutation_recipes[1]), nbhd.mutation_recipes[2:end]
end

function iterate(nbhd::Neighborhood, mutation_recipes::Vector{MutationRecipe})
    if isempty(mutation_recipes)
        nothing
    else
        recipe_consumer(nbhd, mutation_recipes[1]), mutation_recipes[2:end]
    end
end

recipe_consumer(nbhd::Neighborhood, idx::Int)::Shifts =
    perform_mutation(copy(nbhd.shifts), nbhd.mutation_recipes[idx])

recipe_consumer(nbhd::Neighborhood, recipe::MutationRecipe)::Shifts =
    perform_mutation(copy(nbhd.shifts), recipe)

function perform_mutation(shifts::Shifts, recipe::MutationRecipe)::Shifts
    if recipe.type == Mutation.ADD
        shifts[recipe.wrk_no, recipe.day] = recipe.op
    elseif recipe.type == Mutation.DEL
        shifts[recipe.wrk_no, recipe.day] = W
    elseif recipe.type == Mutation.SWP
        shifts[recipe.wrk_no[1], recipe.day], shifts[recipe.wrk_no[2], recipe.day] =
            shifts[recipe.wrk_no[2], recipe.day], shifts[recipe.wrk_no[1], recipe.day]
    else
        @error "Mutation coruppted" recipe.type
    end
    return shifts
end

function get_nbhd(shifts::Shifts)::Vector{MutationRecipe}
    nbhd_recipes = Vector()

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
        append!(nbhd_recipes, mutated_schedules)
    end
    return nbhd_recipes
end

function with_shift_addtion(shifts::Shifts, p_shift)::Vector{MutationRecipe}
    return [
        MutationRecipe((
            Mutation.ADD,
            day = p_shift[2],
            wrk_no = p_shift[1],
            op = allowed_shift,
        )) for allowed_shift in CHANGEABLE_SHIFTS
    ]
end

function with_shift_deletion(shifts::Shifts, p_shift)::Vector{MutationRecipe}
    return [MutationRecipe((
        Mutation.DEL,
        day = p_shift[2],
        wrk_no = p_shift[1],
        op = nothing,
    ))]
end

function with_shift_swap(shifts::Shifts, p_shift)::Vector{MutationRecipe}
    return [
        MutationRecipe((
            Mutation.SWP,
            day = p_shift[2],
            wrk_no = (p_shift[1], o_person),
            op = nothing,
        ))
        for
        o_person in axes(shifts, 1) if
        p_shift[1] < o_person &&
        shifts[o_person, p_shift[2]] in CHANGEABLE_SHIFTS &&
        shifts[o_person, p_shift[2]] != shifts[p_shift]
    ]
end

end # NeighborhoodGen

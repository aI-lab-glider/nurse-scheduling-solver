# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
module NeighborhoodGen

export Neighborhood, get_max_nbhd_size, n_split_nbhd

using ..NurseSchedules:
    Schedule, 
    Shifts, 
    get_changeable_shifts_keys,
    get_shifts, 
    W,
    Mutation, 
    MutationRecipe
    

using StatsBase: sample

import Base: length, iterate, getindex, in

struct Neighborhood
    """
    Frozen shifts logic:

    frozen_shifts is a list of int pairs such that [(worker_number, day_number), ...]

    If zero is provided, it works like a '*' wildcard, so (0, 1) will exclude all shifts on day 1.
    """
    mutation_recipes::Vector{MutationRecipe}
    shifts::Shifts

    function Neighborhood(mutation_recipes::Vector{MutationRecipe}, shifts::Shifts, sample_size::Real=1)
        if sample_size <= 0 || sample_size > 1
            throw(ArgumentError("sample_size must be in range (0,1]"))
        end
        if sample_size == 1
            new(mutation_recipes, shifts)
        else
            size = max(floor(Int, (length(mutation_recipes) * sample_size)), 1)
            new(sample(mutation_recipes, size, replace=false), shifts)
        end
    end

    function Neighborhood(shifts::Shifts, schedule::Schedule)
        mutation_recipes = get_nbhd(shifts, schedule)
        new(mutation_recipes, shifts)
    end

    function Neighborhood(shifts::Shifts, frozen_days::Vector{Int}, schedule::Schedule, sample_size::Real=1)
        allowed_mutations = filter(recipe -> !(recipe.day in frozen_days), get_nbhd(shifts, schedule))
        Neighborhood(allowed_mutations, shifts, sample_size)
    end

    function Neighborhood(shifts::Shifts, frozen_shifts::Vector{Tuple{Int, Int}}, schedule::Schedule, sample_size::Real=1)
        allowed_mutations = filter(recipe -> !(recipe in frozen_shifts), get_nbhd(shifts, schedule))
        Neighborhood(allowed_mutations, shifts, sample_size)
    end
end

function in(recipe::MutationRecipe, frozen_shifts::Vector{Tuple{Int,Int}})
    for (worker_no, day) in frozen_shifts
        worker_no == 0 && day == 0 && @error "Frozen shift '(0, 0)' is forbidden."

        worker_no == 0 && recipe.day == day && return true

        day == 0 && worker_no in recipe.wrk_no && return true

        recipe.day == day && worker_no in recipe.wrk_no && return true
    end
    false
end

length(nbhd::Neighborhood) = length(nbhd.mutation_recipes)

getindex(nbhd::Neighborhood, idx::Int) = consume_recipe(nbhd, idx)

function n_split_nbhd(nbhd::Neighborhood, n::Int)::Vector{Neighborhood}
    mutation_recipies = nbhd.mutation_recipes
    length(mutation_recipies) < n && return Vector(nbhd)

    nbhds = Vector()
    p_len = floor(Int, length(nbhd) / n)
    for i = 1:n
        p_mutation_recipies = if i != n
            splice!(mutation_recipies, 1:p_len)
        else
            mutation_recipies
        end
        push!(nbhds, Neighborhood(p_mutation_recipies, nbhd.shifts))
    end
    return nbhds
end

iterate(nbhd::Neighborhood) =
    consume_recipe(nbhd, nbhd.mutation_recipes[1]), nbhd.mutation_recipes[2:end]

function iterate(nbhd::Neighborhood, mutation_recipes::Vector{MutationRecipe})
    isempty(mutation_recipes) && return nothing
    return consume_recipe(nbhd, mutation_recipes[1]), mutation_recipes[2:end]
end

consume_recipe(nbhd::Neighborhood, idx::Int)::Shifts =
    perform_mutation!(copy(nbhd.shifts), nbhd.mutation_recipes[idx])

consume_recipe(nbhd::Neighborhood, recipe::MutationRecipe)::Shifts =
    perform_mutation!(copy(nbhd.shifts), recipe)

function perform_mutation!(shifts::Shifts, recipe::MutationRecipe)::Shifts
    if recipe.type == Mutation.ADD
        shifts[recipe.wrk_no, recipe.day] = recipe.optional_info
    elseif recipe.type == Mutation.DEL
        shifts[recipe.wrk_no, recipe.day] = W
    elseif recipe.type == Mutation.SWP
        shifts[recipe.wrk_no[1], recipe.day], shifts[recipe.wrk_no[2], recipe.day] =
            shifts[recipe.wrk_no[2], recipe.day], shifts[recipe.wrk_no[1], recipe.day]
    else
        @error "Encountered an unexpected mutation" recipe.type
    end
    return shifts
end

function get_nbhd(shifts::Shifts, schedule::Schedule)::Vector{MutationRecipe}
    nbhd_recipes = Vector()

    for person_shift in CartesianIndices(shifts)
        mutated_schedules = if shifts[person_shift] == W
            with_shift_addtion(shifts, person_shift, schedule)
        elseif shifts[person_shift] in get_changeable_shifts_keys(schedule)
            vcat(
                with_shift_deletion(shifts, person_shift),
                with_shift_swap(shifts, person_shift, schedule),
            )
        else
            []
        end
        append!(nbhd_recipes, mutated_schedules)
    end
    return nbhd_recipes
end

function with_shift_addtion(shifts::Shifts, p_shift, schedule::Schedule)::Vector{MutationRecipe}
    return [
        MutationRecipe((
            Mutation.ADD,
            day = p_shift[2],
            wrk_no = p_shift[1],
            optional_info = allowed_shift,
        )) for allowed_shift in get_changeable_shifts_keys(schedule)
    ]
end

function with_shift_deletion(shifts::Shifts, p_shift)::Vector{MutationRecipe}
    return [MutationRecipe((
        Mutation.DEL,
        day = p_shift[2],
        wrk_no = p_shift[1],
        optional_info = nothing,
    ))]
end

function with_shift_swap(shifts::Shifts, p_shift, schedule::Schedule)::Vector{MutationRecipe}
    return [
        MutationRecipe((
            Mutation.SWP,
            day = p_shift[2],
            wrk_no = (p_shift[1], o_person),
            optional_info = nothing,
        ))
        for
        o_person in axes(shifts, 1) if
        p_shift[1] < o_person &&
        shifts[o_person, p_shift[2]] in get_changeable_shifts_keys(schedule) &&
        shifts[o_person, p_shift[2]] != shifts[p_shift]
    ]
end

function get_max_nbhd_size(shifts::Shifts)::Int
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

end # NeighborhoodGen

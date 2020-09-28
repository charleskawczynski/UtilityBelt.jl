module UtilityBelt

import OrderedCollections
using REPL.TerminalMenus

include("line_count_dir.jl")


"""
    find_files(
        directory::AbstractString,
        include_ext::Vector{String},
        include_filenames::Vector{String} = String[],
        exclude_filenames::Vector{String} = String[],
    )

"""
function find_files(
        directory::AbstractString,
        include_ext::Vector{String},
        include_filenames::Vector{String} = String[],
        exclude_filenames::Vector{String} = String[],
    )
    # all_files = [joinpath(root, f) for (root, dirs, files) in Base.Filesystem.walkdir(directory) for f in files]
    matched_files = []
    for (root, dirs, files) in Base.Filesystem.walkdir(directory)
        for f in files
            full_path = joinpath(root, f)
            if any([occursin(x, full_path) for x in exclude_filenames])
                # @warn "Skipping file $full_path (exclude_filenames)"
                continue
            end
            if !isempty(include_ext) && !any([endswith(f, x) for x in include_ext])
                # @warn "Skipping file $f (include_ext)"
                continue
            end
            if startswith(f, ".")
                @warn "Skipping hidden file $full_path"
                continue
            end
            if !isempty(include_filenames) && !any([occursin(x, full_path) for x in include_filenames])
                @warn "Skipping file $full_path (include_filenames)"
                continue
            end
            push!(matched_files, full_path)
        end
    end
    @info "Files found:\n $(join(matched_files, "\n"))"
    return matched_files
end

"""
    find_in_files(
        directory::AbstractString,
        include_ext::Vector{String},
        include_filenames::Vector{String} = String[],
        exclude_filenames::Vector{String} = String[];
        flags_to_find = String[]
    )
"""
function find_in_files(
        args...;
        flags_to_find = String[]
    )
    found_files = find_files(args...)
    matched_files = String[]
    for f in found_files
        lines = join(readlines(f; keep = true))
        if any([occursin(x, lines) for x in flags_to_find])
            push!(matched_files, f)
        end
    end
    @info "Matched files:\n $(join(matched_files, "\n"))"
    return nothing
end

function remove_dot_mem_files(code_dir::AbstractString)
    all_files = [
        joinpath(root, f) for
        (root, dirs, files) in Base.Filesystem.walkdir(code_dir) for f in files
    ]
    all_mem_files = filter(x -> endswith(x, ".mem"), all_files)
    for f in all_mem_files
        rm(f)
    end
end

"""
    remove_dropbox_conflicts(code_dir::String)

Recursively delete files that match with "... conflicted copy ..."
"""
function remove_dropbox_conflicts(code_dir::AbstractString)
    all_files = [joinpath([root,f]...) for (root, dirs, files) in Base.Filesystem.walkdir(code_dir) for f in files];

    names_to_match = (
        "(LAPTOP-HN9BG775's conflicted copy",
        "(dhcp-103-207.caltech.edu's conflicted copy",
    )

    file_with_conflicts = filter(x->any(occursin(y, x) for y in names_to_match), all_files);

    println("Matched files found:")
    for file in file_with_conflicts
        println("$file")
    end

    options = ["yes", "no"]
    menu = RadioMenu(options, pagesize=4)
    choice = request("Would you like to delete these files?", menu)
    choice == -1 && error("Menu canceled")
    @assert choice == 1 || choice == 2
    if choice == 1
        for file in file_with_conflicts
          println("Deleting file $file")
          rm(file, force=true)
        end
    end
end

"""
    julia_base_folder()

Returns a string of the active Julia Base folder.
"""
julia_base_folder() = dirname(first(Base.functionloc(sin(1))))
julia_folder() = dirname(julia_base_folder())

"""
    open_julia_folder()

Opens the julia base folder in sublime
"""
open_julia_base_folder() = run(`subl $(julia_base_folder())`)
open_julia_folder() = run(`subl $(julia_folder())`)

"""
    walkdir_recursive(directory)

A generator containing all files
in a directory (recursively).
"""
function walkdir_recursive(directory)
    return (joinpath(root, f) for (root, dirs, files) in Base.Filesystem.walkdir(directory) for f in files)
end


end # module

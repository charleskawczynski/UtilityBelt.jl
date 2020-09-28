using OrderedCollections

"""
    line_count_dir(directory::String)

Count lines of code in directory `directory`.
"""
function line_count_dir(directory, extensions, sort_results=true)
    extensions isa AbstractString && (extensions = (extensions,))
    all_files = [joinpath(root, f) for (root, dirs, files) in Base.Filesystem.walkdir(directory) for f in files]
    all_files_no_root = [f for (root, dirs, files) in Base.Filesystem.walkdir(directory) for f in files]
    filter!(x->any([endswith(x, y) for y in extensions]), all_files)
    n_lines = Dict([f=>0 for f in all_files])

    for f in all_files
        if isfile(f)
            n_lines[f] += countlines(f)
        else
            @warn "missing file $f"
        end
    end

    if sort_results
        n_lines = OrderedDict(sort(collect(n_lines), by=x->x[2]))
    end

    println("----------------- Number of lines per file")
    for (f,v) in n_lines
        println("$v \t $f")
    end
    println("----------------- Total number of lines of code:")
    println("n_lines = $(sum(values(n_lines)))")
    return n_lines
end

using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--directory"
            help = "Directory"
            arg_type = String
        "--extensions"
            help = "Extensions to include"
            arg_type = String
        "--sort_results"
            help = "Sort results by number of lines"
            arg_type = Bool
            default = true
    end

    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    line_count_dir(parsed_args["directory"],
                   parsed_args["extensions"],
                   parsed_args["sort_results"])
end

if isinteractive()
    main()
end

module LambdaMaker

using Mustache
using UUIDs

export create_lambda_package, DirectoryExists

struct DirectoryExists <: Exception
    msg::AbstractString
end
Base.show(io::IO, e::DirectoryExists) = println(io, e.msg)

_src_path(filename::AbstractString) = joinpath("..", "template_files", filename)


function _copy_file(dest_dir::AbstractString, filename::AbstractString; force::Bool=false)
    src_path = _src_path(filename)
    dest_path = joinpath(dest_dir, filename)

    cp(src_path, dest_path; force=force)
end


function _render_file(filename::AbstractString, dest_path::AbstractString, render_args::AbstractDict)
    file_path = _src_path(filename)
    rendered_contents = render(read(file_path, String), render_args)

    dest_file_path = joinpath(dest_path, filename)

    open(dest_file_path, "w") do f
        print(f, rendered_contents)
    end
end


function create_lambda_package(package_name::AbstractString; force::Bool=false)
    render_args = Dict(
        "PKG" => package_name,
        "UUID" => string(UUIDs.uuid4())
    )

    # Create a project named directory at the current location
    if isdir(package_name) && !force
        throw(DirectoryExists("Directory $(package_name) already exists. Pass force=true to overwrite."))
    end

    dest_src_path = mkpath(joinpath(package_name, "src"))
    dest_path = dirname(dest_src_path)

    # Copy over bootstrap, Dockerfile, Manifest.toml, handle_requests.jl
    files_to_copy = ["bootstrap", "Manifest.toml", "handle_requests.jl", "template.yml"]
    _copy_file.(dest_path, files_to_copy; force=force)

    # Use Mustache to render the Dockerfile and Project.toml files
    _render_file("Project.toml", dest_path, render_args)
    _render_file("Dockerfile", dest_path, render_args)

    # Special case writing the rendered module.jl into src/package_name.jl
    module_path = joinpath(@__DIR__, "..", "template_files", "src", "module.jl")
    module_rendered = render(read(module_path, String), render_args)

    open(joinpath(dest_src_path, package_name * ".jl"), "w") do f
        print(f, module_rendered)
    end
end

end

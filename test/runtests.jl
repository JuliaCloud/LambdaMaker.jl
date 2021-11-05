using LambdaMaker
using Test

SAMPLE_FILENAME = "Dockerfile"

@testset "_copy_file" begin
    RESOURCE_DIR = mkdir("resources")

    try
        file_path = joinpath(RESOURCE_DIR, SAMPLE_FILENAME)

        @testset "dest file does not exist" begin
            LambdaMaker._copy_file(RESOURCE_DIR, SAMPLE_FILENAME)
            @test isfile(file_path)
        end

        @testset "dest file exists" begin
            @test_throws ArgumentError LambdaMaker._copy_file(RESOURCE_DIR, SAMPLE_FILENAME)
        end

        @testset "force=true" begin
            LambdaMaker._copy_file(RESOURCE_DIR, SAMPLE_FILENAME; force=true)
            @test isfile(file_path)
        end
    finally
        rm(RESOURCE_DIR; force=true, recursive=true)
    end
end

@testset "_render_file" begin
    RESOURCE_DIR = mkdir("resources")
    try
        render_args = Dict("PKG" => "foobar")

        LambdaMaker._render_file(SAMPLE_FILENAME, RESOURCE_DIR, render_args)

        result_file_path = joinpath(RESOURCE_DIR, SAMPLE_FILENAME)
        @test isfile(result_file_path)
    finally
        rm(RESOURCE_DIR; force=true, recursive=true)
    end
end


@testset "create_lambda_package" begin
    project_name = "foobar"

    @testset "project does not exist" begin
        try
            create_lambda_package(project_name)

            @test isdir(project_name)
            @test isfile(joinpath(project_name), "Project.toml")
        finally
            rm(project_name; force=true, recursive=true)
        end
    end

    @testset "project exists & force=false" begin
        try
            mkdir(project_name)
            @test_throws DirectoryExists create_lambda_package(project_name)
        finally
            rm(project_name)
        end
    end

    @testset "project exists & force=true" begin
        try
            mkdir(project_name)
            create_lambda_package(project_name; force=true)
            @test isdir(project_name)
        finally
            rm(project_name; force=true, recursive=true)
        end
    end
end

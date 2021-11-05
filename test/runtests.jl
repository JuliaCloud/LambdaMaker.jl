using LambdaMaker
using Test

SAMPLE_FILENAME = "Dockerfile"
PROJECT_NAME = "foobar"

@testset "_copy_file" begin
    mktempdir() do RESOURCE_DIR
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
    end
end

@testset "_render_file" begin
    mktempdir() do RESOURCE_DIR
        render_args = Dict("PKG" => PROJECT_NAME)
        LambdaMaker._render_file(SAMPLE_FILENAME, RESOURCE_DIR, render_args)

        result_file_path = joinpath(RESOURCE_DIR, SAMPLE_FILENAME)
        @test isfile(result_file_path)

        contents = read(result_file_path, String)
        @test contains(contents, "CMD [\"$(PROJECT_NAME).handle_event\"]")
    end
end


@testset "create_lambda_package" begin
    function get_project_files()
        for (_, _, files) in walkdir(joinpath(@__DIR__, "..", "template_files"))
            return files
        end
    end

    function test_file_existance()
        for project_file in get_project_files()
            @test isfile(joinpath(PROJECT_NAME, project_file))
        end
    end

    @testset "project does not exist" begin
        try
            create_lambda_package(PROJECT_NAME)
            test_file_existance()
        finally
            rm(PROJECT_NAME; force=true, recursive=true)
        end
    end

    @testset "project exists & force=false" begin
        try
            mkdir(PROJECT_NAME)
            @test_throws DirectoryExists create_lambda_package(PROJECT_NAME)
        finally
            rm(PROJECT_NAME)
        end
    end

    @testset "project exists & force=true" begin
        try
            mkdir(PROJECT_NAME)
            create_lambda_package(PROJECT_NAME; force=true)
            test_file_existance()
        finally
            rm(PROJECT_NAME; force=true, recursive=true)
        end
    end
end

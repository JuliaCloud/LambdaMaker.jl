# LambdaMaker.jl
This package is intended to generate all the boilerplate code required to deploy an AWS Lambda function via AWS SAM.

## Prerequisites
You will need to download and install the following:

- [AWS SAM](https://aws.amazon.com/serverless/sam/)
- [Docker](https://www.docker.com/)

## How to generate the boilerplate code
You will need to generate a new project by running,

```julia
using LambdaMaker

create_lambda_package("project_name")
```

If a directory already exists with the `project_name`, an error is thrown and the directory is left untouched.
You can pass `force=true` as a `kwarg` to overwrite it.

This will create a new directory in your working directory with the following files:
- `bootstrap`: This is the file which Lambda will use when it first runs
- `Dockerfile`: Defines the Docker image that will run in the Lambda environment
- `handle_requests.jl`: Reads the Lambda invocations, calls your code, and writes the responses
- `Project.toml`: Basic TOML for defining your package to be deployed on Lambda
- `template.yml`: The CloudFormation stack which will be created when deploying via AWS SAM
- `src/{project_name}.jl`: A module with the boilerplate `handle_event(event_data, headers)` function

## What you need to modify
You will need to modify the `src/{project_name}.jl` file to include whatever code you wish to run in the Lambda function.
The entrypoint for Lambda will be the `handle_event(event_data, headers)` function, you will need to modify this to call the functions you wish to invoke.

**Note:** If you want to specify an `ENTRYPOINT` script in the Dockerfile (e.g. to set some environment variables), you must explicitly run the bootstrap file in that script. 

## Workflow for building, testing, and deploying a Lambda function
AWS SAM documentation can be found [here](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html).
The short-handed version is,

Build your Docker image as:
```bash
sam build
```

Test locally by running:
```bash
sam local invoke JuliaFunction
```

If your function requires some form of input see the appendix for more information.

When you are satisfied and want to deploy your function,
```bash
sam deploy --guided
```

If you want to update your function, you can use [SAM sync](https://aws.amazon.com/blogs/compute/accelerating-serverless-development-with-aws-sam-accelerate/).


## Appendix

### Other resources
- [tk3369/aws-lambda-container-julia](https://github.com/tk3369/aws-lambda-container-julia)
### Passing input to your function
Passing inputs is usually done in the JSON format.
You will need to add a package to parse this information, such as [JSON3.jl](https://github.com/quinnj/JSON3.jl).

After generating the boilerplate code and adding in your JSON parsing functionality you will need to modify the `src/project_name.jl`.
Modify the `handle_event()` function as,

```julia
module MyPackage

using JSON3

function handle_event(event_data, headers)
    input = JSON3.read(event_data)[:input_variable]
    return your_function(input)
end

end
```

You will then need to define a JSON file to pass into your function as,

```json
{
    "input_variable": 10
}
```

To pass this event JSON file when localy testing as,

```bash
sam local invoke -e event.json JuliaFunction
```

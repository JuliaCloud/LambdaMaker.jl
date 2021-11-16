using Downloads

const AWS_LAMBDA_RUNTIME_API = ENV["AWS_LAMBDA_RUNTIME_API"]
const HANDLER = ENV["_HANDLER"]  # from Dockerfile's CMD command
const LAMBDA_TASK_ROOT = ENV["LAMBDA_TASK_ROOT"]
const RUNTIME_URL = "http://$AWS_LAMBDA_RUNTIME_API/2018-06-01"

abstract type State end
struct Start <: State end
struct Received <: State end
struct Handled <: State end

function error(::Start, exception, request_id)
    @error "Unable to receive request" exception
end

function error(::Received, exception, request_id)
    @error "Unable to handle event" exception request_id
    post_error("runtime/invocation/$request_id/error", exception)
end

function error(::Handled, exception, request_id)
    @error "Unable to notify lambda runtime (invocation response)" exception request_id
end


function http_get(url)
    io = IOBuffer()
    response = request(url; output=io)

    seekstart(io)
    body = read(io, String)

    return response.headers, body
end

function http_post(url, headers, body)
    io = IOBuffer()
    write(io, body)
    seekstart(io)  # We need to seekstart for the runtime to properly read the body

    return request(url, method="POST", headers=headers, input=io)
end

function post_error(path::AbstractString, ex::Exception)
    headers = [
        "Content-type" => "application/json",
        "Lambda-Runtime-Function-Error-Type" => typeof(ex),
    ]

    url = "$RUNTIME_URL/$path"

    try
        http_post(url, headers, """{"errorType": "$(typeof(ex))", "errorMessage": "$(ex)"}""")
        @info "Notified lambda runtime about the error" url ex
    catch failure
        @error "Unable to notify lambda runtime about the error" url ex failure
    end
end

# Initialize Lambda function by loading user module
try
    @info "Loading user module"
    global mod, func = Symbol.(split(HANDLER, "."))
    @eval using $(mod)
catch ex
    @error "Initializtion error" ex
    post_error("runtime/init/error", ex)
    @info "Shutting down container"
    exit(1)
end

const MY_MODULE = Base.eval(Main, mod)
const MY_HANDLER = Base.eval(MY_MODULE, func)

@info "Start processing requests"
while true
    local state, request_id
    try
        state = Start()
        request_headers, request_body = http_get("$RUNTIME_URL/runtime/invocation/next")
        request_id_idx = findfirst(x -> lowercase(x[1]) == "lambda-runtime-aws-request-id", request_headers)
        request_id = request_headers[request_id_idx][2]
        @info "Received event" request_id
        state = Received()

        response = MY_HANDLER(request_body, request_headers)

        @info "Got response from handler" response
        state = Handled()

        http_post("$RUNTIME_URL/runtime/invocation/$request_id/response", [], response)
        @info "Notified Lambda Runtime"
    catch ex
        error(state, ex, request_id)
    end
end

@info "All done"

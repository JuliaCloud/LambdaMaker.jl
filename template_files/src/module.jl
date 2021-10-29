
module {{{PKG}}}

# Define a handler function that is called by the Lambda runtime
function handle_event(event_data, headers)
    @info "Handling request" event_data headers
    return "Hello World!"
end

end

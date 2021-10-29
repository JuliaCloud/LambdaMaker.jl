
module MonteCarlo

using JSON3

# Calculate π using Monte Carlo simulation
function monte_carlo_pi(n)
    inside((x, y)) = x * x + y * y < 1.0
    points = rand(2, n)
    hits = count(inside(points[:, v]) for v in 1:n)
    return hits / n * 4
end

function parse_data(event_data)
    return JSON3.read(event_data)[:monte_carlo_sims]
end

format_result(value) = "$value"

# Define a handler function that is called by the lambda runtime
function handle_event(event_data, headers)
    @info "Handling request" event_data headers
    simulations = parse_data(event_data)
    my_pi = monte_carlo_pi(simulations)
    return format_result(my_pi)
end

end

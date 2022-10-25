
function set_timeout(req_channel, resp_channel, end_time::Float64)
    # try
    #     @info "Setting timeout $end_time"
    if isready(req_channel)
        # @info "Request channel is not empty"
        take!(req_channel)
    end
    if isready(resp_channel)
        # @info "Response channel is not empty"
        take!(resp_channel)
    end
    put!(req_channel, (0, end_time))
    # @info "Waiting for set master response"
    depth = take!(resp_channel)
    if depth == -1
        # @info "Can't add new timeout, waiting for interrupt to arrive $depth"
        while true
            sleep(1)
        end
    end
    # @info "Set timeout for depth $depth"
    return depth
    # catch e
    #     if isa(e, InterruptException)
    #         @info "Got interrupt exception while trying to set timeout $end_time"
    #         @info "Request channel is ready $(isready(req_channel))"
    #         @info "Response channel is ready $(isready(resp_channel))"
    #     else
    #         @info "Got exception $e while trying to set timeout $end_time"
    #         @info "Request channel is ready $(isready(req_channel))"
    #         @info "Response channel is ready $(isready(resp_channel))"
    #     end
    #     rethrow()
    # end
end

function remove_timeout(req_channel, resp_channel, depth::Int)
    # try
    #     @info "Removing unused timeout $depth"
    if isready(req_channel)
        # @info "Request channel is not empty"
        take!(req_channel)
    end
    if isready(resp_channel)
        # @info "Response channel is not empty"
        take!(resp_channel)
    end
    put!(req_channel, (1, depth, 0))
    # @info "Waiting for remove unused master response"
    status = take!(resp_channel)
    # @info "Removed unused timeout $depth"
    if status == 1
        # @info "Waiting for interrupt to arrive $depth"
        while true
            sleep(1)
        end
    end
    # catch e
    #     if isa(e, InterruptException)
    #         @info "Got interrupt exception while trying to remove unused timeout $depth"
    #         @info "Request channel is ready $(isready(req_channel))"
    #         @info "Response channel is ready $(isready(resp_channel))"
    #     else
    #         @info "Got exception $e while trying to remove unused timeout $depth"
    #         @info "Request channel is ready $(isready(req_channel))"
    #         @info "Response channel is ready $(isready(resp_channel))"
    #     end
    #     rethrow()
    # end
end

function clean_fired_timeout(req_channel, resp_channel, depth::Int)
    # try
    #     @info "Removing fired timeout $depth"
    if isready(req_channel)
        # @info "Request channel is not empty"
        take!(req_channel)
    end
    if isready(resp_channel)
        # @info "Response channel is not empty"
        take!(resp_channel)
    end
    put!(req_channel, (1, depth, 1))
    # @info "Waiting for remove fired master response"
    status = take!(resp_channel)
    if status == 1
        error("Wrong timeout status on cleanup $depth")
    elseif status == 2
        # @warn "Rethrowing incorrectly catched interrupt $depth"
        rethrow()
    else
        # @info "Removed fired timeout $depth"
    end
    # catch e
    #     if isa(e, InterruptException)
    #         @info "Got interrupt exception while trying to remove fired timeout $depth"
    #         @info "Request channel is ready $(isready(req_channel))"
    #         @info "Response channel is ready $(isready(resp_channel))"
    #     else
    #         @info "Got exception $e while trying to remove fired timeout $depth"
    #         @info "Request channel is ready $(isready(req_channel))"
    #         @info "Response channel is ready $(isready(resp_channel))"
    #     end
    #     rethrow()
    # end
end

macro run_with_timeout(run_context, timeout_key, expr)
    return quote
        local context = $(esc(run_context))
        if !haskey(context, "timeout_request_channel")
            $(esc(expr))
        else
            local timeout = context[$(esc(timeout_key))]
            local end_time = time() + timeout
            local req_channel = context["timeout_request_channel"]
            local resp_channel = context["timeout_response_channel"]
            local depth = set_timeout(req_channel, resp_channel, end_time)

            local result = nothing
            try
                got_interrupt = false
                try
                    result = $(esc(expr))
                catch e
                    if isa(e, InterruptException)
                        got_interrupt = true
                    end
                    rethrow()
                finally
                    if !got_interrupt
                        remove_timeout(req_channel, resp_channel, depth)
                    end
                end
            catch e
                if isa(e, InterruptException)
                    clean_fired_timeout(req_channel, resp_channel, depth)
                else
                    rethrow()
                end
            end
            result
        end
    end
end

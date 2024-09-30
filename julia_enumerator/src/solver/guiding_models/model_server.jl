
struct GuidingModelServer
    model::Any
    worker_register_channel::RemoteChannel
    worker_register_result_channel::RemoteChannel
    request_channel::RemoteChannel
    result_channels::Dict{Int,RemoteChannel}
end

function GuidingModelServer(model)
    worker_register_channel = RemoteChannel(() -> Channel{Int}(20))
    worker_register_result_channel = RemoteChannel(() -> Channel{Any}(20))
    request_channel = RemoteChannel(() -> Channel{Any}(100))
    result_channels = Dict{Int,RemoteChannel}()
    return GuidingModelServer(
        model,
        worker_register_channel,
        worker_register_result_channel,
        request_channel,
        result_channels,
    )
end

function _registration_loop(server::GuidingModelServer)
    while true
        worker_id = take!(server.worker_register_channel)
        if !haskey(server.result_channels, worker_id)
            result_channel = RemoteChannel(() -> Channel{Any}(100))
            server.result_channels[worker_id] = result_channel
        end
        put!(
            server.worker_register_result_channel,
            (worker_id, server.request_channel, server.result_channels[worker_id]),
        )
    end
end

function _guiding_processing_loop(server::GuidingModelServer)
    while true
        request = take!(server.request_channel)
        worker_id, (grammar, input, output, trace_val, is_rev) = request
        worker_ids = [worker_id]
        batch = ([input], [output], [trace_val], [is_rev])
        while isready(server.request_channel)
            request = take!(server.request_channel)
            worker_id, (_, input, output, trace_val, is_rev) = request
            push!(worker_ids, worker_id)
            push!(batch[1], input)
            push!(batch[2], output)
            push!(batch[3], trace_val)
            push!(batch[4], is_rev)
        end

        model_inputs = (grammar, batch[1:3]..., hcat(batch[4]...))
        # @info model_inputs

        guiding_result = run_guiding_model(server.model, model_inputs)
        # @info "Batch size: $(length(worker_ids))"
        for (i, worker_id) in enumerate(worker_ids)
            result_channel = server.result_channels[worker_id]
            worker_result = guiding_result[:, i]
            put!(result_channel, worker_result)
        end
    end
end

function start_server(server::GuidingModelServer)
    Threads.@spawn _registration_loop(server)
    Threads.@spawn _guiding_processing_loop(server)
end

function stop_server(server::GuidingModelServer)
    close(server.worker_register_channel)
    close(server.worker_register_result_channel)
    close(server.request_channel)
    for (worker_id, result_channel) in server.result_channels
        close(result_channel)
    end
    @info "Guiding model server stopped"
end

function generate_grammar(sc::SolutionContext, guiding_model_channels, grammar, entry_id, is_known)
    str_grammar = vcat([string(p) for p in grammar], ["\$0", "lambda", "\$v1"])
    inputs = Dict()
    for (var_id, name) in sc.input_keys
        # Using var id as branch id because they are the same for input variables
        entry = sc.entries[sc.branch_entries[var_id]]
        inputs[name] = (sc.types[entry.type_id], entry.values)
    end
    output_entry = sc.entries[sc.branch_entries[sc.target_branch_id]]
    output = string((sc.types[output_entry.type_id], output_entry.values))

    val_entry = sc.entries[entry_id]
    trace_val = string((sc.types[val_entry.type_id], val_entry.values))

    model_inputs = (str_grammar, string(inputs), output, trace_val, [is_known])

    begin
        put!(guiding_model_channels[1], (myid(), model_inputs))
        result = take!(guiding_model_channels[2])
    end

    log_variable = result[end-2]
    log_lambda = result[end-1]
    log_free_var = result[end]
    productions = Tuple{Program,Tp,Float64}[(p, p.t, result[i]) for (i, p) in enumerate(grammar)]
    g = Grammar(log_variable, log_lambda, log_free_var, productions, nothing)
    return make_dummy_contextual(g)
end

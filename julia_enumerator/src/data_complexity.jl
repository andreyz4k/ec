
function get_complexity_summary(values, t::TypeConstructor)
    result = Accumulator{String,Int64}()
    result[t.name] = 1
    if isempty(t.arguments)
        return result
    elseif length(t.arguments) == 1
        merge!(result, [get_complexity_summary(v, t.arguments[1]) for v in values]...)
        return result
    else
        error("unsupported type constructor: " + t.name)
    end
end

function get_complexity_summary(values::EitherOptions, t::TypeConstructor)
    result = Accumulator{String,Int64}()
    for (h, option) in values.options
        merge!(result, get_complexity_summary(option, t))
    end
    for (k, count) in result
        result[k] = div(count, length(values.options))
    end
    return result
end

function get_complexity_summary_max(values::EitherOptions, t::TypeConstructor)
    result = Accumulator{String,Int64}()
    for (h, option) in values.options
        op_summary = get_complexity_summary_max(option, t)
        for (k, v) in op_summary
            if !haskey(result, k) || result[k] < v
                result[k] = v
            end
        end
    end
    return result
end

function get_complexity(sc::SolutionContext, summary::Accumulator)
    return sum(sc.type_weights[tname] * count for (tname, count) in summary; init = 0.0)
end

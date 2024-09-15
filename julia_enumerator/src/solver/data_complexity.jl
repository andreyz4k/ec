
function get_complexity_summary(values, t)
    accum = Accumulator{String,Int64}()
    for value in values
        get_complexity_summary(value, t, accum)
    end
    return accum
end

function get_complexity_summary(@nospecialize(values), t::TypeConstructor, accum)
    inc!(accum, t.name)
    if isempty(t.arguments)
        return
    elseif length(t.arguments) == 1
        for v in values
            get_complexity_summary(v, t.arguments[1], accum)
        end
    elseif length(t.arguments) == 2
        get_complexity_summary(values[1], t.arguments[1], accum)
        get_complexity_summary(values[2], t.arguments[2], accum)
    else
        error("unsupported type constructor: $(t.name)")
    end
end

function get_complexity_summary(values::AnyObject, t::TypeVariable, accum)
    inc!(accum, "any")
end

function get_complexity_summary(values::AnyObject, t::TypeConstructor, accum)
    inc!(accum, t.name)
    for arg in t.arguments
        get_complexity_summary(values, arg, accum)
    end
end

function get_complexity_summary(values::Nothing, t::TypeConstructor, accum) end
function get_complexity_summary(values::Nothing, t::TypeVariable, accum) end

function get_complexity_summary(values::EitherOptions, t::TypeConstructor, accum)
    result = Accumulator{String,Int64}()
    for (h, option) in values.options
        get_complexity_summary(option, t, result)
    end
    for (k, count) in result
        inc!(accum, k, div(count, length(values.options)))
    end
end

get_complexity_summary(values::PatternWrapper, t::TypeConstructor, accum) =
    get_complexity_summary(values.value, t, accum)
get_complexity_summary(values::PatternWrapper, t::TypeVariable, accum) = get_complexity_summary(values.value, t, accum)

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

get_complexity_summary(values::AbductibleValue, t::TypeConstructor, accum) =
    get_complexity_summary(values.value, t, accum)
get_complexity_summary(values::AbductibleValue, t::TypeVariable, accum) = get_complexity_summary(values.value, t, accum)

function get_complexity(sc::SolutionContext, summary::Accumulator)
    return sum(sc.type_weights[tname] * count for (tname, count) in summary; init = 0.0)
end

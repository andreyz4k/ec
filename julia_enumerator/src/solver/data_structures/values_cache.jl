
struct RandomAccessCache
    max_size::Int
    values::Set{Any}
end

RandomAccessCache(max_size::Int) = RandomAccessCache(max_size, Set{Any}())

Base.isempty(cache::RandomAccessCache) = isempty(cache.values)

Base.push!(cache::RandomAccessCache, value) = begin
    push!(cache.values, value)
    while length(cache.values) > cache.max_size
        el = rand(cache.values)
        delete!(cache.values, el)
    end
end

select_random(cache::RandomAccessCache) = rand(cache.values)

VALUES_CACHE_SIZE = 1000

examples_counts = Set{Int}()
single_value_cache = DefaultDict{Tp,RandomAccessCache}(() -> RandomAccessCache(VALUES_CACHE_SIZE))
multi_value_cache = DefaultDict(() -> DefaultDict{Tp,RandomAccessCache}(() -> RandomAccessCache(VALUES_CACHE_SIZE)))

function save_values_to_cache(tp::Tp, values)
    for value in values
        push!(single_value_cache[tp], value)
    end
    push!(multi_value_cache[length(values)][tp], values)
end

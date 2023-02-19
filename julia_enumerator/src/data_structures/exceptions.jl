
struct EnumerationException <: Exception
    msg::String
end

EnumerationException() = EnumerationException("Error during enumeration")

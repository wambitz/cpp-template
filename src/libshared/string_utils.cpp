#include "string_utils.hpp"

#include <algorithm>

std::string to_upper(const std::string& s)
{
    std::string r = s;
    std::transform(r.begin(), r.end(), r.begin(), ::toupper);
    return r;
}
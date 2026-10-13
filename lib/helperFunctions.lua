local helper = {}

function helper.split_string(inputstr, sep)
    if sep == nil then
      sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      table.insert(t, str)
    end
    return t
  end

function helper.print_table(_table)
    print(textutils.serialise(_table))
end


function helper.padString(inputStr, padChar, length)
    local strLen = #tostring(inputStr)
    if strLen >= length then
        return inputStr
    else
        local padLen = length - strLen
        return tostring(inputStr) .. string.rep(padChar, padLen)
    end
end

-- Rounds to the given number of decimal places (defaults to 2, i.e. cents).
function helper.round(value, decimal_places)
    local mult = 10 ^ (decimal_places or 2)
    return math.floor(value * mult + 0.5) / mult
end

function helper.clamp(value, min, max)
    if value < min then
        value = min
    elseif value > max then
        value = max
    end
    return helper.round(value)
end

function helper.mergeTables(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
    return t1
end

return helper
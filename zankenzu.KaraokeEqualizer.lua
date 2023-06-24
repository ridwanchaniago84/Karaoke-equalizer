script_name = "Karaoke equalizer"
script_description = "Make time syl equalizer"
script_author = "Zankenzu"
script_version = "0.1"

function split(line, pattern)
    local parts = {}

    for content in line:gmatch(pattern) do
        table.insert(parts, content)
    end

    return parts
end

function thisNumber(input)
    if tonumber(input) == nil then
        return false
    end

    return true
end

function getTimeKara(line, saveIndexCurl)
    splittedCurl = split(line, "{(.-)}")

    local karaTimes = {}

    for iCurl, tags in ipairs(splittedCurl) do
        local splittedKaraokeTags = split(tags, "([^\\k]+)")

        for iTime, karaTime in ipairs(splittedKaraokeTags) do
            if not thisNumber(karaTime) then
                goto continue
            end

            if saveIndexCurl then
                table.insert(karaTimes, {
                    index = iCurl,
                    time = karaTime
                })
                goto continue
            end

            table.insert(karaTimes, karaTime)

            ::continue::
        end
    end

    return karaTimes
end

function main(subs, sel)
    if #sel <= 1 then
        aegisub.debug.out('Please select multi line!')
        return
    end

    local refLine
    local changeLine
    local changeLineIndex

    for x, i in ipairs(sel) do
        if x == 1 then
            refLine = subs[i]
        end

        if x == 2 then
            changeLineIndex = i
            changeLine = subs[i]
        end
    end

    local refKaraTimes = getTimeKara(refLine.text, false)
    local changeKaraTimes = getTimeKara(changeLine.text, true)
    local curlyTags = split(changeLine.text, "{(.-)}")

    local curlyIndex = 1
    local newCurlyTags = {}

    for i, kTime in ipairs(changeKaraTimes) do
        local kTimeIndex = tonumber(kTime.index)
        local tag = {}

        if curlyIndex < kTimeIndex then
            while curlyIndex < kTimeIndex do
                tag = {
                    index = curlyIndex,
                    tag = "{" .. curlyTags[curlyIndex]
                }

                table.insert(newCurlyTags, tag)
                curlyIndex = curlyIndex + 1
            end
        end

        tag = {
            index = kTimeIndex,
            tag = "{" .. curlyTags[kTimeIndex]:gsub(kTime.time, refKaraTimes[i])
        }
        table.insert(newCurlyTags, tag)

        curlyIndex = curlyIndex + 1
    end

    local emptyTagSub = subs[changeLineIndex].text:gsub("%b{}", "{}")
    local syls = split(emptyTagSub, "[^{]+")
    local finishText = subs[changeLineIndex]
    finishText.text = ""

    for i, tag in ipairs(newCurlyTags) do
        finishText.text = finishText.text .. tag.tag .. syls[tag.index]
    end

    subs[changeLineIndex] = finishText

    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, main)

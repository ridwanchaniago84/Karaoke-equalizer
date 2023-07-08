--[[
The MIT License (MIT)

Copyright (c) 2023 Zankenzu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

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
            local karaokeTag = 'k'

            if not thisNumber(karaTime) then
                local firstChar = string.sub(karaTime, 1, 1)

                if firstChar == 'K' or firstChar == 'f' or firstChar == 'o' then
                    karaTime = karaTime:sub(2)

                    if thisNumber(karaTime) then
                        karaokeTag = firstChar == 'K' and 'K' or 'k' .. firstChar
                        goto continueProcess
                    end
                end

                goto continue
            end

            ::continueProcess::
            if saveIndexCurl then
                table.insert(karaTimes, {
                    index = iCurl,
                    time = karaTime,
                    tag = karaokeTag
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
        aegisub.debug.out('Please select multiple line!')
        return
    end

    local refLine

    for x, i in ipairs(sel) do
        if x == 1 then
            refLine = subs[i]
            goto endLine
        end

        local refKaraTimes = getTimeKara(refLine.text, false)
        local changeKaraTimes = getTimeKara(subs[i].text, true)

        if #refKaraTimes ~= #changeKaraTimes or refLine.start_time ~= subs[i].start_time or refLine.end_time ~= subs[i].end_time then
            refLine = subs[i]
            goto endLine
        end

        local curlyTags = split(subs[i].text, "{(.-)}")

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
                tag = "{" ..
                    curlyTags[kTimeIndex]:gsub([[\]] .. kTime.tag .. kTime.time, [[\]] .. kTime.tag .. refKaraTimes[i])
            }
            table.insert(newCurlyTags, tag)

            curlyIndex = curlyIndex + 1
        end

        local emptyTagSub = subs[i].text:gsub("%b{}", "{}")
        local syls = split(emptyTagSub, "[^{]+")
        local finishText = subs[i]
        finishText.text = ""

        for i, tag in ipairs(newCurlyTags) do
            finishText.text = finishText.text .. tag.tag .. syls[tag.index]
        end

        subs[i] = finishText

        ::endLine::
    end

    aegisub.set_undo_point(script_name)
    return sel
end

aegisub.register_macro(script_name, script_description, main)

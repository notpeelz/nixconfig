import os
import sys
import re
import math

openingRegexp = re.compile(r"(\\*)({)")
closingRegexp = re.compile(r"(\\*)(})")
separatorRegexp = re.compile(r"(\\*)(,)")
escapeRegexp = re.compile(r"(\\+)(?:(.)|$)")
rangeRegexp = re.compile(r"^(?:[A-Za-z]-[a-z]|[A-Z]-[A-Z]|[0-9]-[0-9])$")

PART_LITERAL = 0
PART_GROUP = 1

def isEscaped(match):
    return len(match.group(1)) % 2 == 1

def matchToken(it, ignoreEscaped=True):
    # find the next token
    match = next(it, None)

    if not ignoreEscaped:
        return match

    # skip all of the escaped tokens
    while match != None and isEscaped(match):
        match = next(it, None)

    return match

def unescape(s):
    offset = 0
    while True:
        it = escapeRegexp.finditer(s, offset)
        match = matchToken(it, ignoreEscaped=False)
        if match == None:
            break

        pos = match.span(1)

        # this is the escaped character
        escaped_char = match.group(2)

        # this is the amount of backslashes that precede the character
        escape_count = len(match.group(1))

        # we want to get rid of half of the backslashes but leave the last one if odd
        # \\\\\n -> \\\n
        escapes_to_keep = math.ceil(escape_count / 2)

        # XXX: we allow escaping - because of keysym ranges -- not sure if
        # this is compliant with the sxhkd parser
        if escape_count % 2 == 1 and not escaped_char in list("{},\\-_"):
            if pos[1] == len(s):
                raise Exception(f"Invalid escape sequence '\\'")
            else:
                raise Exception(f"Invalid escape sequence '\\{escaped_char}'")

        # delete the backslashes (do the actual unescaping)
        s = s[:pos[1] - escapes_to_keep] + s[pos[1]:]
        offset = pos[1]

    return s

def parse(s):
    def appendLiteral(s):
        if s:
            parts.append((PART_LITERAL, unescape(s)))
    def appendGroup(g):
        g = list(filter(lambda x: x, [unescape(entry) for entry in g]))
        if g:
            parts.append((PART_GROUP, g))

    parts = []
    opening_it = openingRegexp.finditer(s)
    closing_it = closingRegexp.finditer(s)
    opening_pos = None
    closing_pos = None
    while True:
        prev_closing_pos = closing_pos

        # find the next opening brace
        match_opening = matchToken(opening_it)
        if match_opening == None:
            if prev_closing_pos == None:
                # there's no braces; add the text as is
                appendLiteral(s)
            elif prev_closing_pos[1] != len(s):
                # we reached the last group but there's still trailing text
                appendLiteral(s[prev_closing_pos[1]:])
            break

        # grab the position of the opening brace
        opening_pos = match_opening.span(2)

        # find the next closing brace
        match_closing = matchToken(closing_it)
        if match_closing == None:
            raise Exception(f"Unterminated group at position {opening_pos[0]}")

        # grab the position of the closing brace
        closing_pos = match_closing.span(2)

        # make sure that the closing brace doesn't come before the opening brace
        if closing_pos[0] < opening_pos[0]:
            raise Exception(f"Unexpected token '{s[closing_pos[0]]} at position {closing_pos[0]}")

        # add the text inbetween groups
        if parts:
            appendLiteral(s[prev_closing_pos[1]:opening_pos[0]])
        # add the leading text (before the first group)
        elif opening_pos[0] > 0:
            appendLiteral(s[:opening_pos[0]])

        # add the group
        appendGroup(parseGroup(s[opening_pos[1]:closing_pos[0]]))

    # make sure we don't have any trailing closing braces
    m = matchToken(closing_it)
    if m != None:
        raise Exception(f"Unexpected token '{s[m.span(2)[0]]}' at position {m.span(2)[0]}")

    return parts

def parseGroup(s):
    it = separatorRegexp.finditer(s)
    parts = []
    match = None
    end = 0
    # split the values based on the separator (comma)
    while True:
        previous_match = match
        match = matchToken(it)
        if match == None:
            if previous_match == None:
                parts.append(s)
            break
        begin = previous_match.span(2)[1] if previous_match != None else 0
        end = match.span(2)[0]
        parts.append(s[begin:end])

    if previous_match != None:
        parts.append(s[end+1:])

    return parts

# handle special sxhkd characters
def parseVariant(variant):
    # underscores are empty placeholders
    if variant == "_":
        return [""]

    # keysym ranges
    if rangeRegexp.match(variant):
        values = []
        begin = variant[0]
        end = variant[2]
        if ord(begin) > ord(end):
            raise Exception("Decrementing keysym ranges aren't supported")
        for x in range(ord(begin), ord(end)+1):
            values.append(chr(x))
        return values

    # single value
    return [variant]

def generateVariants(parts):
    if not parts:
        return

    part = parts[0]
    rest = parts[1:]
    if part[0] == PART_GROUP:
        for variant in part[1]:
            values = parseVariant(variant)
            if rest:
                for x in generateVariants(rest):
                    for v in values:
                        yield v + x
            else:
                for v in values:
                    yield v
    else:
        if rest:
            for x in generateVariants(rest):
                yield part[1] + x
        else:
            yield part[1]

gettrace = getattr(sys, 'gettrace', None)
if gettrace != None and gettrace():
    # supply test values if we're debugging
    hotkey = "hyper + shift + {_,F}{1,2,3,4,5,6,7,8,9}"
    cmd = "bspc node focused -d {_,1}{0,1,2,3,4,5,6,7,8} --follow"
else:
    # use file descriptors 3 and 4 as data streams
    hotkey = os.fdopen(3, "r").read()
    cmd = os.fdopen(4, "r").read()

hotkey_parts = parse(hotkey)
cmd_parts = parse(cmd)

hotkeys = list(generateVariants(hotkey_parts))
scripts = list(generateVariants(cmd_parts))

def isPartEquivalent(part, other):
    if part[0] == PART_GROUP and other[0] == PART_GROUP:
        partVariants = sum([parseVariant(v) for v in part[1]], [])
        otherVariants = sum([parseVariant(v) for v in other[1]], [])
        return len(partVariants) == len(otherVariants)
    return part[0] == other[0]

arePartsValid = [isPartEquivalent(hkpart, cmdpart) for hkpart, cmdpart in zip(hotkeys, scripts)]
if all(arePartsValid):
    raise Exception("Mismatching group(s)")

if len(scripts) > len(hotkeys):
    raise Exception("Too many groups in script")

# XXX: sxhkd doesn't seem to care about this
# if len(scripts) < len(hotkeys):
#     raise Exception("Not enough groups in script")

# generate hotkey variants
numberOfDigits = len(str(len(hotkeys)))
for i, hotkey in enumerate(hotkeys):
    with open(os.open(f"script-{str(i).zfill(numberOfDigits)}.sh", os.O_CREAT | os.O_WRONLY, 0o755), mode="w") as f:
        f.write("#!/usr/bin/env bash\n\n")
        f.write("# ")
        f.write(hotkey)
        f.write("\n")

        # if we run out of subsitution groups, just use the last one as sxhkd
        # doesn't seem to care if we don't have enough groups in the script
        if i >= len(scripts):
            f.write(scripts[-1])
        else:
            f.write(scripts[i])

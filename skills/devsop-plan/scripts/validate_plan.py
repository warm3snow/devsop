#!/usr/bin/env python3
"""Structural validator for devsop-plan artifacts (plan.md).

Checks the plan contract from the devsop-plan skill: an explicit
Non-goals section, at least one story with a narrative and at least one
Given/When/Then scenario (including a negative or boundary scenario),
valid type tags, scenario IDs prefixed by their story number, and an NFR
section whose entries carry a constraint and a scenario. Technical values
in Then lines produce warnings, not errors.

Usage: python3 validate_plan.py <plan.md>
Exit: 0 = structurally valid, 1 = errors found, 2 = usage/IO error.
"""
import re
import sys

STORY_HEADING = re.compile(r'^## (US-\d+)\s+(.+?)\s*\[(Must|Should|Could)\]$')
SCENARIO_HEADING = re.compile(r'^### S(\d+)\.(\d+)\s+(.+?)\s*\[([a-z0-9]+)\]$')
NFR_HEADING = re.compile(r'^### (NFR-\d+)\s+(.+?)\s*\[([a-z0-9]+)\]$')
TYPE_TAGS = ('unit', 'integration', 'manual')
NARRATIVE = re.compile(r'(?i)^as an? .*\bi want\b.*\bso that\b')
NEGATIVE = re.compile(r'(?i)negative|boundary|invalid|empty|reject|missing|'
                      r'error|fail|exceed|limit|too\s|unauthori[sz]ed|forbidden')
TECHNICAL_THEN = re.compile(r'(?i)\bhttp\b|\bapi\b|'
                            r'\b(200|201|204|400|401|403|404|409|500)\b')


def sub_sections(lines, start, end):
    """Yield (heading, start, end) for '### ' blocks within [start, end)."""
    starts = [i for i in range(start, end) if lines[i].startswith('### ')]
    for pos, sub_start in enumerate(starts):
        sub_end = starts[pos + 1] if pos + 1 < len(starts) else end
        yield lines[sub_start], sub_start, sub_end


def check_scenario(heading, start, end, lines, story_num, sid, errors, warnings):
    """Validate one '### S<story>.<n> <name> [type]' block."""
    match = SCENARIO_HEADING.match(heading)
    if match is None:
        errors.append("line %d: scenario heading %r does not match "
                      "'### S<story>.<n> <name> [unit|integration|manual]'"
                      % (start + 1, heading))
        return
    prefix, _index, name, tag = match.groups()
    if int(prefix) != story_num:
        errors.append("line %d: scenario '%s' prefix does not match its story %s"
                      % (start + 1, heading.strip(), sid))
    if tag not in TYPE_TAGS:
        errors.append("line %d: scenario '%s' has invalid type tag '%s' "
                      "(unit|integration|manual)" % (start + 1, name, tag))
    text = '\n'.join(lines[start + 1:end])
    for keyword in ('Given', 'When', 'Then'):
        if keyword not in text:
            errors.append("line %d: scenario '%s' is missing '%s'"
                          % (start + 1, name, keyword))
    for offset, line in enumerate(lines[start + 1:end]):
        if re.match(r'^\s*-?\s*Then\b', line) and TECHNICAL_THEN.search(line):
            warnings.append("line %d: technical value in Then of scenario "
                            "'%s' belongs to devsop-design's interface "
                            "contract" % (start + 2 + offset, name))


def check_nfr_section(lines, start, end, errors):
    """Validate the '## Non-functional requirements' entries."""
    for heading, sub_start, sub_end in sub_sections(lines, start, end):
        match = NFR_HEADING.match(heading)
        if match is None:
            errors.append("line %d: NFR heading %r does not match "
                          "'### NFR-<id> <name> [unit|integration|manual]'"
                          % (sub_start + 1, heading))
            continue
        nid, _name, tag = match.groups()
        if tag not in TYPE_TAGS:
            errors.append("line %d: %s has invalid type tag '%s' "
                          "(unit|integration|manual)"
                          % (sub_start + 1, nid, tag))
        text = '\n'.join(lines[sub_start + 1:sub_end])
        if 'Constraint:' not in text:
            errors.append("line %d: %s has no 'Constraint:' line"
                          % (sub_start + 1, nid))
        for keyword in ('Given', 'When', 'Then'):
            if keyword not in text:
                errors.append("line %d: %s scenario is missing '%s'"
                              % (sub_start + 1, nid, keyword))


def main():
    if len(sys.argv) != 2:
        print('Usage: validate_plan.py <plan.md>', file=sys.stderr)
        return 2
    path = sys.argv[1]
    try:
        with open(path, encoding='utf-8') as handle:
            lines = handle.read().splitlines()
    except OSError as exc:
        print('Cannot read %s: %s' % (path, exc), file=sys.stderr)
        return 2

    errors = []
    warnings = []
    stories = []
    has_non_goals = False

    starts = [i for i, line in enumerate(lines) if line.startswith('## ')]
    for pos, start in enumerate(starts):
        end = starts[pos + 1] if pos + 1 < len(starts) else len(lines)
        heading = lines[start]
        if heading.startswith('## Non-goals'):
            has_non_goals = True
            if not [l for l in lines[start + 1:end] if l.startswith('- ')]:
                errors.append("line %d: '## Non-goals' section is empty "
                              "(state '- None' explicitly when there are none)"
                              % (start + 1))
        elif heading.startswith('## Non-functional requirements'):
            check_nfr_section(lines, start, end, errors)
        else:
            match = STORY_HEADING.match(heading)
            if match:
                stories.append((match, start, end))

    if not has_non_goals:
        errors.append("missing the '## Non-goals' section "
                      "(state '- None' explicitly when there are none)")

    if not stories:
        errors.append("no '## US-<n> <title> [Must|Should|Could]' story found")

    for match, start, end in stories:
        sid = match.group(1)
        num = int(sid.split('-', 1)[1])
        if not any(NARRATIVE.match(line.strip())
                   for line in lines[start + 1:end]):
            errors.append("line %d: %s has no narrative "
                          "('As a <role> I want <capability> so that <benefit>')"
                          % (start + 1, sid))
        scenarios = list(sub_sections(lines, start, end))
        if not scenarios:
            errors.append("line %d: %s has no '### S%d.<n> <name> "
                          "[unit|integration|manual]' scenario"
                          % (start + 1, sid, num))
        has_negative = False
        for heading, sub_start, sub_end in scenarios:
            check_scenario(heading, sub_start, sub_end, lines,
                           num, sid, errors, warnings)
            if NEGATIVE.search('\n'.join(lines[sub_start:sub_end])):
                has_negative = True
        if scenarios and not has_negative:
            errors.append("line %d: %s has no negative or boundary scenario"
                          % (start + 1, sid))

    for entry in warnings:
        print('[WARN] %s' % entry)
    for entry in errors:
        print('[ERROR] %s' % entry)
    print('%s: %d error(s), %d warning(s)' % (path, len(errors), len(warnings)))
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())

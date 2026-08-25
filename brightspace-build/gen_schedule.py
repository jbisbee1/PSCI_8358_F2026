# -*- coding: utf-8 -*-
"""Derive module release (ModuleStartDate) targets from the same WEEKS
table used by gen_manifest.py, and write schedule.json:
  { "<module title exactly as created>": "<UTC ISO-8601 StartDate>", ... }

Release time = 00:00 America/Chicago on the week's date (DST-aware via
zoneinfo, not hand-computed). Syllabus module is left unscheduled
(always visible). Supplementary/Reference module releases with Week 1.
"""
import json
from datetime import datetime
from zoneinfo import ZoneInfo
from pathlib import Path

import gen_manifest as gm  # reuse WEEKS + module-title formatting

CT = ZoneInfo("America/Chicago")
UTC = ZoneInfo("UTC")

schedule = {}
week1_start = None
for w in gm.WEEKS:
    n = w["n"]
    if n > 13:
        continue  # weeks 14-16 have no module built this pass
    mod_title = f"Week {n:02d} ({w['date']}): {w['title']}"
    local_midnight = datetime.strptime(w["date"], "%Y-%m-%d").replace(
        hour=0, minute=0, second=0, tzinfo=CT)
    utc_start = local_midnight.astimezone(UTC).strftime("%Y-%m-%dT%H:%M:%S.000Z")
    schedule[mod_title] = utc_start
    if n == 1:
        week1_start = utc_start

schedule["Supplementary / Reference Readings"] = week1_start
# Syllabus intentionally omitted -- always visible, no release gate.

out = Path(__file__).resolve().parent / "schedule.json"
out.write_text(json.dumps(schedule, indent=2), encoding="utf-8")
print(f"Wrote {out} ({len(schedule)} modules scheduled)")
for title, ts in schedule.items():
    print(f"  {ts}  {title}")

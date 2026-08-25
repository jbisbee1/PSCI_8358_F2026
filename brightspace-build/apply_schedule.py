# -*- coding: utf-8 -*-
"""
Sets ModuleStartDate on already-created top-level content modules, matched
by exact title, from schedule.json. NOT part of the skill's shipped verbs
(bscourse.py's ensure_module hardcodes ModuleStartDate: None on create and
has no update path) -- this is a small standalone extension that reuses
the skill's authenticated client (bsapi.BS) and follows its own rules:
GET the whole object first, change only ModuleStartDate, PUT the whole
object back, then re-GET to verify.

Usage:
  python apply_schedule.py --ou 648878                      # dry run (default)
  python apply_schedule.py --ou 648878 --execute --i-mean-production
"""
import argparse
import json
import sys
from pathlib import Path

SKILL_SCRIPTS = Path(r"C:\Users\Jimbo\.claude\plugins\cache\brightspace-skills\brightspace-course\3b1a9be430b3\scripts")
sys.path.insert(0, str(SKILL_SCRIPTS))
from bsapi import HOST, LE, PRODUCTION_HOSTS, BS, die  # noqa: E402

BUILD = Path(__file__).resolve().parent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ou", type=int, required=True)
    ap.add_argument("--execute", action="store_true")
    ap.add_argument("--i-mean-production", action="store_true")
    args = ap.parse_args()

    schedule = json.loads((BUILD / "schedule.json").read_text(encoding="utf-8"))

    bs = BS()  # loads/mints token same as every other verb
    root = bs.jget(f"/d2l/api/le/{LE}/{args.ou}/content/root/")
    by_title = {e.get("Title"): e.get("Id") for e in root if e.get("Type") == 0}

    print(f"Plan: set ModuleStartDate on {len(schedule)} module(s) in "
          f"ou={args.ou} on {HOST}:")
    missing = []
    plan = []
    for title, start in schedule.items():
        mid = by_title.get(title)
        if mid is None:
            missing.append(title)
            continue
        plan.append((title, mid, start))
        print(f"  {title!r} (id {mid}) -> ModuleStartDate = {start}")
    if missing:
        print("\n  NOT FOUND (skipped -- run the main apply --execute first):")
        for t in missing:
            print(f"    - {t}")

    if not args.execute:
        print("\nDRY RUN -- nothing was changed. Re-run with --execute "
              "(after confirming the plan and the ou with the user).")
        return
    if HOST in PRODUCTION_HOSTS and not args.i_mean_production:
        die(f"{HOST} is PRODUCTION. Re-run with --i-mean-production after "
            "explicit user confirmation, or set BRIGHTSPACE_HOST to the "
            "test tenant.")

    for title, mid, start in plan:
        obj = bs.jget(f"/d2l/api/le/{LE}/{args.ou}/content/modules/{mid}")
        obj["ModuleStartDate"] = start
        bs.put(f"/d2l/api/le/{LE}/{args.ou}/content/modules/{mid}", json=obj)
        got = bs.jget(f"/d2l/api/le/{LE}/{args.ou}/content/modules/{mid}")
        if (got.get("ModuleStartDate") or "")[:16] != start[:16]:
            die(f"module {mid} '{title}': read-back ModuleStartDate is "
                f"{got.get('ModuleStartDate')} (expected {start})")
        print(f"OK: module {mid} '{title}' verified start={got.get('ModuleStartDate')}")

    print(f"\nApply complete: {len(plan)} module(s) scheduled.")


if __name__ == "__main__":
    main()

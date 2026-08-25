# -*- coding: utf-8 -*-
"""
Replaces the existing 'Syllabus' content topic with the regenerated
pages/syllabus.html. `apply` is idempotent-by-title (skips instead of
diffing content), so an in-place content change needs an explicit
delete + recreate of that one topic. Follows the skill's own rules:
plan printed first, --execute + --i-mean-production gated on prod,
delete verified (topic gone), recreate verified (topic back, same title).

Usage:
  python update_syllabus.py --ou 648878                      # dry run
  python update_syllabus.py --ou 648878 --execute --i-mean-production
"""
import argparse
import sys
from pathlib import Path

SKILL_SCRIPTS = Path(r"C:\Users\Jimbo\.claude\plugins\cache\brightspace-skills\brightspace-course\3b1a9be430b3\scripts")
sys.path.insert(0, str(SKILL_SCRIPTS))
from bsapi import HOST, LE, PRODUCTION_HOSTS, BS, die  # noqa: E402
import bscourse as bc  # noqa: E402

BUILD = Path(__file__).resolve().parent
MODULE_TITLE = "Syllabus"
TOPIC_TITLE = "Syllabus"
NEW_FILE = BUILD / "pages" / "syllabus.html"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ou", type=int, required=True)
    ap.add_argument("--execute", action="store_true")
    ap.add_argument("--i-mean-production", action="store_true")
    args = ap.parse_args()

    bs = BS()
    mid = bc.find_module(bs, args.ou, MODULE_TITLE)
    if mid is None:
        die(f"module '{MODULE_TITLE}' not found in ou={args.ou}")
    structure = bc.module_structure(bs, args.ou, mid)
    topic = next((t for t in structure if t.get("Title") == TOPIC_TITLE), None)
    if topic is None:
        die(f"topic '{TOPIC_TITLE}' not found in module {mid}")
    tid = topic["Id"]

    print(f"Plan: DELETE topic '{TOPIC_TITLE}' (id {tid}) from module "
          f"'{MODULE_TITLE}' (id {mid}), then re-upload {NEW_FILE.name} "
          f"({NEW_FILE.stat().st_size} bytes) as a new topic with the "
          f"same title, in ou={args.ou} on {HOST}")

    if not args.execute:
        print("\nDRY RUN -- nothing was changed. Re-run with --execute "
              "(after confirming the plan and the ou with the user).")
        return
    if HOST in PRODUCTION_HOSTS and not args.i_mean_production:
        die(f"{HOST} is PRODUCTION. Re-run with --i-mean-production after "
            "explicit user confirmation, or set BRIGHTSPACE_HOST to the "
            "test tenant.")

    bs.delete(f"/d2l/api/le/{LE}/{args.ou}/content/topics/{tid}")
    structure = bc.module_structure(bs, args.ou, mid)
    if any(t.get("Id") == tid for t in structure):
        die(f"topic {tid} still present after delete")
    print(f"OK: old topic {tid} deleted (verified)")

    org_code = bc.get_org_code(bs, args.ou)
    new_tid = bc.upload_file_topic(bs, args.ou, mid, org_code, TOPIC_TITLE, NEW_FILE)
    structure = bc.module_structure(bs, args.ou, mid)
    titles = [t.get("Title") for t in structure]
    if TOPIC_TITLE not in titles:
        die(f"new syllabus topic {new_tid} did not appear in module {mid} "
            "(200 != landed)")
    print(f"OK: new topic {new_tid} '{TOPIC_TITLE}' verified in module {mid}")


if __name__ == "__main__":
    main()

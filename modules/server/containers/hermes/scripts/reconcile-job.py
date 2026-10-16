"""Apply one named job declaration without replacing scheduler state."""
import json
import sys

from cron.jobs import create_job, parse_schedule, resolve_job_ref, update_job


def reconcile(spec):
    job = resolve_job_ref(spec["name"])
    if job is None:
        return create_job(**spec)
    changes = {}
    for key, value in spec.items():
        expected = parse_schedule(value) if key == "schedule" else value
        if job.get(key) != expected:
            changes[key] = value
    if changes:
        return update_job(job["id"], changes)
    return job


if __name__ == "__main__":
    with open(sys.argv[1]) as stream:
        reconcile(json.load(stream))

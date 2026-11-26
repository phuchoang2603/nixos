import argparse
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

API = "https://api.capsolver.com"
TASKS = {
    "recaptcha-v2": "ReCaptchaV2TaskProxyLess",
    "recaptcha-v3": "ReCaptchaV3TaskProxyLess",
    "turnstile": "AntiTurnstileTaskProxyLess",
}


def post(path, body):
    request = urllib.request.Request(
        API + path, json.dumps(body).encode(), {"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def main():
    parser = argparse.ArgumentParser(description="Solve a CAPTCHA with CapSolver and print the token.")
    parser.add_argument("kind", choices=TASKS)
    parser.add_argument("--url", required=True, help="Page URL that shows the CAPTCHA")
    parser.add_argument("--sitekey", required=True)
    parser.add_argument("--action", help="reCAPTCHA v3 action")
    args = parser.parse_args()

    key = os.environ.get("CAPSOLVER_API_KEY") or (Path.home() / ".capsolver-key").read_text().strip()
    task = {"type": TASKS[args.kind], "websiteURL": args.url, "websiteKey": args.sitekey}
    if args.action:
        task["pageAction"] = args.action
    created = post("/createTask", {"clientKey": key, "task": task})
    if created.get("errorId"):
        sys.exit(f"CapSolver refused the task: {created.get('errorCode')}: {created.get('errorDescription')}")
    for _ in range(40):
        time.sleep(3)
        result = post("/getTaskResult", {"clientKey": key, "taskId": created["taskId"]})
        if result.get("errorId"):
            sys.exit(f"CapSolver failed: {result.get('errorCode')}: {result.get('errorDescription')}")
        if result.get("status") == "ready":
            solution = result["solution"]
            print(solution.get("gRecaptchaResponse") or solution["token"])
            return
    sys.exit("CapSolver timed out")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
import re
import datetime

STATE_FILE = "/home/pn/internships/state.json"
CONFIG_FILE = "/home/pn/internships/config.json"
REPO_API = "https://api.github.com/repos/SimplifyJobs/Summer2027-Internships/commits?sha=dev&per_page=1"
LISTINGS_URL = "https://raw.githubusercontent.com/SimplifyJobs/Summer2027-Internships/dev/.github/scripts/listings.json"

US_STATES = {
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY', 'DC'
}

US_STATE_NAMES = [
    'alabama', 'alaska', 'arizona', 'arkansas', 'california', 'colorado', 'connecticut',
    'delaware', 'florida', 'georgia', 'hawaii', 'idaho', 'illinois', 'indiana', 'iowa',
    'kansas', 'kentucky', 'louisiana', 'maine', 'maryland', 'massachusetts', 'michigan',
    'minnesota', 'mississippi', 'missouri', 'montana', 'nebraska', 'nevada', 'new hampshire',
    'new jersey', 'new mexico', 'new york', 'north carolina', 'north dakota', 'ohio',
    'oklahoma', 'oregon', 'pennsylvania', 'rhode island', 'south carolina', 'south dakota',
    'tennessee', 'texas', 'utah', 'vermont', 'virginia', 'washington', 'west virginia',
    'wisconsin', 'wyoming', 'district of columbia'
]

NON_US_KEYWORDS = [
    'canada', 'uk', 'united kingdom', 'london', 'ireland', 'germany', 'france',
    'india', 'japan', 'singapore', 'australia', 'netherlands', 'sweden',
    'switzerland', 'poland', 'spain', 'italy', 'brazil', 'mexico', 'israel',
    'china', 'taiwan', 'korea', 'belfast', 'toronto', 'vancouver', 'montreal',
    'waterloo', 'ottawa', 'calgary', 'berlin', 'munich', 'paris', 'dublin',
    'bengaluru', 'bangalore', 'tokyo', 'sydney', 'melbourne', 'edinburgh', 'cambridge',
    'oxford', 'manchester', 'bristol', 'birmingham, uk', 'londonderry'
]

def is_us_location(loc_str):
    if not loc_str:
        return False
    loc_lower = loc_str.lower().strip()
    for nkw in NON_US_KEYWORDS:
        if nkw in loc_lower:
            return False
    if any(k in loc_lower for k in ['remote in usa', 'remote in us', 'remote (us)', 'remote, us', 'united states', 'usa']):
        return True
    if loc_str.strip() in ['SF', 'NYC', 'Remote', 'South SF', 'LA']:
        return True
    m = re.search(r',\s*([A-Z]{2})\b', loc_str)
    if m and m.group(1) in US_STATES:
        return True
    for sn in US_STATE_NAMES:
        if sn in loc_lower:
            return True
    return False

def matches_felix_profile(job):
    if not job.get('active'):
        return False, 'inactive'
    terms = job.get('terms', [])
    if not any('2027' in str(t) for t in terms):
        return False, 'not_2027'

    locs = job.get('locations', [])
    if locs and not any(is_us_location(l) for l in locs):
        return False, 'non_us'

    title = job.get('title', '').lower()
    degrees = job.get('degrees', [])

    if degrees and "Bachelor's" not in degrees:
        return False, 'requires_advanced_degree'
    if 'phd' in title or 'doctoral' in title or 'postdoc' in title or 'mba intern' in title:
        return False, 'phd_or_mba'

    exclude_keywords = [
        'mechanical', 'hardware', 'electrical', 'fpga', 'asic', 'pcb', 'rf ', 'silicon',
        'sales', 'marketing', 'human resources', 'recruiting', 'talent', 'legal', 'accounting',
        'finance intern', 'financial analyst', 'graphic design', 'ui/ux', 'ux design',
        'product designer', 'supply chain', 'chemical', 'civil engineer', 'construction',
        'biomedical', 'clinical', 'nurse', 'content creator', 'social media', 'tax intern',
        'audit intern', 'underwriting', 'actuarial', 'operations intern'
    ]
    # Exclude TikTok / ByteDance per Felix
    company = job.get('company_name', '').lower()
    if 'tiktok' in company or 'bytedance' in company:
        return False, 'excluded_tiktok_bytedance'

    # Check US Citizenship / Clearance exclusions
    defense_contractors = [
        'northrop grumman', 'lockheed martin', 'general dynamics', 'rtx', 'raytheon',
        'leidos', 'booz allen', 'l3harris', 'draper', 'parsons', 'jhu apl',
        'johns hopkins applied physics', 'bae systems', 'huntington ingalls'
    ]
    for dc in defense_contractors:
        if dc in company:
            return False, f'defense_contractor_{dc}'

    clearance_keywords = [
        'security clearance', 'secret clearance', 'top secret', 'ts/sci', 'ts-sci',
        'active clearance', 'u.s. citizenship required', 'us citizenship required',
        'must be a u.s. citizen', 'must be a us citizen', 'only u.s. citizens',
        'only us citizens', 'dod clearance', 'polygraph', 'clearance required',
        'public trust clearance', 'itar'
    ]
    for ck in clearance_keywords:
        if ck in title:
            return False, f'clearance_required_{ck}'

    # Exclude Data roles per Felix
    data_keywords = [
        'data science', 'data scientist', 'data engineer', 'data analytics', 'data analyst',
        'business intelligence', 'bi intern', 'bi developer', 'bi analyst', 'data mining',
        'data operations', 'analytics intern', 'data intern'
    ]
    for dk in data_keywords:
        if dk in title:
            return False, f'excluded_data_role_{dk}'

    # Exclude Mobile and Frontend roles per Felix
    mobile_frontend_keywords = [
        'mobile', 'ios', 'android', 'frontend', 'front-end', 'front end',
        'web developer', 'web and mobile', 'react native', 'flutter', 'ui engineer'
    ]
    for mfk in mobile_frontend_keywords:
        if mfk in title:
            return False, f'excluded_mobile_frontend_{mfk}'

    for ek in exclude_keywords:
        if ek in title:
            return False, f'excluded_{ek}'

    include_keywords = [
        'software', 'swe', 'developer', 'backend', 'full stack',
        'fullstack', 'systems', 'infrastructure', 'platform', 'cloud', 'devops', 'sre',
        'site reliability', 'distributed', 'machine learning', 'ai ',
        'ai/ml', 'artificial intelligence', 'computer vision', 'deep learning', 'mlops',
        'security engineer', 'embedded software', 'firmware', 'cuda', 'gpu',
        'quantitative developer', 'quant developer', 'technologist'
    ]
    for ik in include_keywords:
        if ik in title:
            return True, f'matched_{ik}'

    cat = job.get('category', '')
    if cat in ['Software', 'Software Engineering']:
        return True, 'category_matched'

    return False, 'unmatched'

def load_state():
    if os.path.exists(STATE_FILE):
        try:
            with open(STATE_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            pass
    return {"last_commit_sha": None, "seen_job_ids": [], "job_threads": {}}

def save_state(state):
    os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
    with open(STATE_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def fetch_json(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Hermes-Internship-Bot/1.0'})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode('utf-8'))

def format_forum_post(job):
    company = job.get('company_name', 'Company')
    title = job.get('title', 'Intern')
    locs = ", ".join([l for l in job.get('locations', []) if is_us_location(l)] or job.get('locations', []))
    apply_url = job.get('url', '')
    simplify_id = job.get('id', '')
    simplify_url = f"https://simplify.jobs/p/{simplify_id}" if simplify_id else ""
    sponsorship = job.get('sponsorship', 'Not specified')

    post_title = f"{company} — {title} (Summer 2027)"[:100]

    body = [
        f"## 🏢 {company} — {title}",
        f"**Term:** Summer 2027 | **Sponsorship:** {sponsorship}",
        f"**📍 Location:** {locs}",
        "",
        "### 🔗 Application Links",
        f"• **Direct Apply:** <{apply_url}>" if apply_url else "• Direct Apply: N/A",
        f"• **Simplify Copilot:** <{simplify_url}>" if simplify_url else "",
        f"• **Desktop Browser Preview:** [Open in hermes-desktop](https://desktop.home.phuchoang.sbs)",
        "",
        "### 📄 Job Description",
        f"**Employer listing:** <{apply_url}>" if apply_url else "**Employer listing:** unavailable",
        "The JD summary, requirements and full text will be added to this thread before applying.",
        "",
        "### 📋 Application Checklist",
        "- [ ] Check role requirements & US eligibility",
        "- [ ] Open application page in desktop browser",
        "- [ ] Autofill / populate fields with `Updated_Resume.pdf`",
        "- [ ] Create or sign in to the applicant account if required",
        "- [ ] Verify fields, submit automatically & confirm success",
        "- [ ] Update status in [Google Sheets Tracker](https://docs.google.com/spreadsheets/d/1APq4s7g3qEd1Wz5IqOYhmkdYNZiVHITbF4Q1XYd8mis/edit?usp=drivesdk)"
    ]

    return post_title, "\n".join([line for line in body if line])

def post_to_discord_webhook(webhook_url, post_title, content):
    payload = {
        "thread_name": post_title,
        "content": content,
        "allowed_mentions": {"parse": []}
    }
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        f"{webhook_url}?wait=true",
        data=data,
        headers={'Content-Type': 'application/json', 'User-Agent': 'Hermes-Bot/1.0'}
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        if resp.getcode() in [200, 201]:
            res = json.loads(resp.read().decode())
            return res.get("channel_id")  # Return thread_id
    return None


def main():
    init_mode = '--init' in sys.argv
    state = load_state()
    config = load_config()
    webhook_url = config.get("discord_webhook_url")
    seen_ids = set(state.get("seen_job_ids", []))

    try:
        commit_data = fetch_json(REPO_API)
        latest_sha = commit_data[0]['sha']
    except Exception as e:
        latest_sha = None

    if not init_mode and latest_sha and state.get("last_commit_sha") == latest_sha:
        print("[SILENT]")
        return

    try:
        listings = fetch_json(LISTINGS_URL)
    except Exception as e:
        print(f"Error fetching listings: {e}")
        return

    if init_mode:
        all_ids = [job['id'] for job in listings if 'id' in job]
        state['last_commit_sha'] = latest_sha
        state['seen_job_ids'] = all_ids
        state['initialized_at'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        save_state(state)
        print(f"Initialized state with {len(all_ids)} existing job listings.")
        return

    new_matching = []
    for job in listings:
        job_id = job.get('id')
        if not job_id or job_id in seen_ids:
            continue

        matched, reason = matches_felix_profile(job)
        if matched:
            new_matching.append(job)

        seen_ids.add(job_id)

    state['last_commit_sha'] = latest_sha
    state['seen_job_ids'] = list(seen_ids)
    state['last_run_at'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    save_state(state)

    if not new_matching:
        print("[SILENT]")
        return

    # If webhook is configured, create native forum posts!
    if webhook_url:
        created_jobs = []
        job_threads = state.setdefault("job_threads", {})
        for job in new_matching:
            title, content = format_forum_post(job)
            try:
                thread_id = post_to_discord_webhook(webhook_url, title, content)
                if thread_id:
                    job["thread_id"] = thread_id
                    if job.get("id"):
                        job_threads[job["id"]] = thread_id
                    created_jobs.append(job)
            except Exception as e:
                pass
        save_state(state)
        if not created_jobs:
            print("[SILENT]")
            return
        output_lines = [
            f"🚀 **Created {len(created_jobs)} new post(s) in your tasks forum channel:**",
            ""
        ]
        for idx, job in enumerate(created_jobs, 1):
            company = job.get('company_name', 'Unknown')
            title = job.get('title', 'Unknown')
            apply_url = job.get('url', '')
            output_lines.append(f"{idx}. **{company} — {title}** (<{apply_url}>)")
        output_lines.append("")
        output_lines.append("Read each employer JD and add its summary/full text to the existing task thread, then continue with internship-application-assistant; submit and verify eligible applications.")
        print("\n".join(output_lines))
        return

    # Fallback to single markdown digest if webhook is not set
    output_lines = [
        f"🎯 **Found {len(new_matching)} New Summer 2027 Internship Application(s)** matching your profile:\n"
    ]
    for idx, job in enumerate(new_matching, 1):
        title, content = format_forum_post(job)
        output_lines.append(f"### Post #{idx}: {title}")
        output_lines.append(content)
        output_lines.append("\n" + "="*40 + "\n")

    print("\n".join(output_lines))

if __name__ == '__main__':
    main()

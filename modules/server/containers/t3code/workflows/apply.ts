import { execFile } from "node:child_process";

const { workflow, step, agent, stop, skip, title, every } = T3;

const MAX_JOBS_PER_RUN = 6;
const PARALLEL_AGENTS = 3;

const callExecutor = (path, input) =>
  new Promise((resolve, reject) => {
    execFile(
      "executor",
      ["call", `tools["job-applications"].${path}`, "--input", JSON.stringify(input)],
      { maxBuffer: 32 * 1024 * 1024, timeout: 180000 },
      (error, stdout) => {
        if (error) return reject(error);
        const call = JSON.parse(stdout).execution?.value;
        if (!call?.ok) return reject(new Error(`${path} failed: ${JSON.stringify(call?.error ?? call).slice(0, 300)}`));
        resolve(call.value);
      },
    );
  });

const Job = Schema.Struct({ id: Schema.String, company: Schema.String, title: Schema.String });
const Outcome = Schema.Struct({
  outcome: Schema.Literals(["submitted", "closed", "needs_you", "uncertain", "skipped", "dry_run"]),
  note: Schema.String,
});

const loadQueue = async () => {
  const settings = await callExecutor("get_settings", {});
  if (!settings.applicationsEnabled) return [];
  const ready = (await callExecutor("list_jobs", { status: "Ready", limit: 50 })).items;
  const fresh = (await callExecutor("list_jobs", { status: "New", limit: 100 })).items;
  const oldestFirst = (a, b) => a.created_at - b.created_at;
  return [...ready.sort(oldestFirst), ...fresh.sort(oldestFirst)]
    .slice(0, MAX_JOBS_PER_RUN)
    .map((job) => ({ id: job.id, company: job.company, title: job.title }));
};

const brief = (job, dryRun) =>
  [
    `Use the \`apply\` skill for exactly one job: ${job.id} (${job.company}, ${job.title}).`,
    "Other agents are working other jobs in parallel. Do not touch any other job, queue or browser tab.",
    dryRun
      ? "DRY RUN: screen and prepare, fill the application up to its review page and stop without submitting."
      : "Screen it and, if it is eligible, apply to the end and record the outcome.",
    "When you finish, submit your result with the outcome and a one-line note.",
  ].join("\n");

workflow(
  "apply",
  {
    version: 1,
    payload: Schema.Struct({ scheduledAt: Schema.String, dryRun: Schema.optional(Schema.Boolean) }),
    triggers: [every("20 minutes")],
    concurrency: 1,
  },
  Effect.fn(function* (payload) {
    yield* title(`Apply ${payload.scheduledAt.slice(0, 16)}`);

    // The feed is checked with its ETag, so an unchanged feed costs nothing.
    yield* step.try(
      "discover",
      { returns: Schema.Struct({ inserted: Schema.Number }) },
      Effect.tryPromise({ try: () => callExecutor("discover_jobs", { force: false }), catch: (error) => error }),
    );

    const queue = yield* step(
      "queue",
      { returns: Schema.Array(Job) },
      Effect.tryPromise({ try: loadQueue, catch: (error) => error }),
    );
    if (queue.length === 0) return yield* skip("nothing to apply to");
    yield* title(`Apply ${payload.scheduledAt.slice(0, 16)}: ${queue.length} jobs`);

    const results = yield* Effect.all(
      queue.map((job) =>
        agent.try(`job-${job.id}`, {
          project: "/workspace/job-applications",
          title: `${job.company}: ${job.title}`.slice(0, 80),
          brief: brief(job, payload.dryRun === true),
          returns: Outcome,
          model: { instanceId: "antigravity", model: "gemini-4-hydrogen", options: [{ id: "thought_level", value: "medium" }] },
          runtimeMode: "full-access",
          timeout: "40 minutes",
        }),
      ),
      { concurrency: PARALLEL_AGENTS },
    );

    const failed = results.filter((result) => result.outcome === "failed").length;
    if (failed === results.length) return yield* stop(`all ${failed} agents failed`);
    return { jobs: queue.length, failed };
  }),
);

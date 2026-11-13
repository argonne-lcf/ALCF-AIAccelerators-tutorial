# Claude_Integrate_SN.md: Integrating Claude Code with SambaNova

Author: Tim Clarke, SambaNova Systems
License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

Give this file to a fresh Claude Code session and ask it to set up the integration. Claude should read it end to end, ask for the values listed in **Inputs** before changing anything, then follow the steps in order.

Source: SambaNova's Claude Code integration guide (https://docs.sambanova.ai/docs/en/integrations/claude-code), with additional fixes noted in **Known gotchas** and **Known differences from the SambaNova guide**. The defaults target SambaNova Cloud. For an on-prem instance, see **On-prem instances** at the end.

---

## Instructions for Claude

1. Do not write or change any config until the user has supplied the **Inputs** below. Ask for any that are missing, one question at a time if needed.
2. Never print API keys back to the user, and never commit them to git. Keys go only in `~/.claude/settings.json` or the user's shell profile.
3. Start with Option B unless the user explicitly wants a single SambaNova model for the whole session, in which case use Option A (see **Choose an option**).
4. Run the verification steps and report pass or fail for each. Do not claim success without running them.

---

## Inputs

Collect these from the user before starting:

| Name | Example | Notes |
|---|---|---|
| `SN_BASE_URL` | `https://api.sambanova.ai/v1` | The SambaNova endpoint. Default to this unless the user names an on-prem host. |
| `SN_API_KEY` | `sk-...` | The SambaNova API key. Treat as secret. |
| `SN_MODEL` | `MiniMax-M3` | A model id the instance actually serves. Confirm with the list-models check below. |
| Option | A or B | See **Choose an option**. |

---

## Choose an option

**Recommended: start with Option B (Plugin).** It keeps a frontier model in the planning seat while a cheaper SambaNova model does the bulk execution. Use Option A only if you specifically want one SambaNova model to run the whole session.

| | Option A: Direct API | Option B: Plugin (recommended) |
|---|---|---|
| How it works | Claude Code talks straight to the SambaNova Anthropic-compatible Messages API. The SambaNova model runs the whole session. | An Anthropic model (for example Opus) plans in the main session and delegates execution to a SambaNova model through the `/code` sub-agent. |
| Setup | Environment variables, then launch. | Install the plugin, register models locally. |
| Tools | Local tools and MCP servers work. Anthropic server-side tools such as web search do not. | Main session has full tools. The `/code` sub-agent has filesystem and shell only, no MCP. |
| Choose when | You want the simplest path, or you want to evaluate a SambaNova model as an end-to-end coding agent. | You want frontier planning with cheap, fast bulk execution. |

---

## Prerequisites

- Claude Code installed and launchable from a terminal.
- A SambaNova API key from cloud.sambanova.ai/apis (or a valid key for an on-prem instance).
- For Option B: Python 3.11 or newer on `PATH` (3.10 fails silently), and `opencode` installed (`curl -fsSL https://opencode.ai/install | bash`).

---

## Option A: Direct API

### 1. Set environment variables

Add these to `~/.zshrc` (or the user's shell profile), replacing the placeholders:

```bash
export ANTHROPIC_BASE_URL="https://api.sambanova.ai"
export ANTHROPIC_API_KEY="<SN_API_KEY>"
export ANTHROPIC_MODEL="<SN_MODEL>"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="<SN_MODEL>"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

Two points that matter:

- `ANTHROPIC_BASE_URL` must not end in `/v1`. The SDK appends `/v1/messages` itself. A trailing `/v1` produces a 404.
- Set `ANTHROPIC_DEFAULT_HAIKU_MODEL` as well as `ANTHROPIC_MODEL`. Claude Code uses a small "Haiku"-class model for background tasks, including the permission classifier. If that is not mapped to a model the instance serves, those tasks fail or hang silently.

Launch Claude Code from a fresh shell so the variables are present.

### 2. Verify

```bash
curl -s "<SN_BASE_URL>/models" -H "Authorization: Bearer $ANTHROPIC_API_KEY"
```

Confirm `<SN_MODEL>` appears in the response. Then start `claude` and send a short prompt. It should get an answer from the SambaNova model.

---

## Option B: Plugin

### 1. Set the API keys

The plugin needs **two** variables. The SambaNova guide mentions only the first. Set both to the same value:

- `SAMBANOVA_API_KEY`: used for registry operations such as listing models.
- `SAMBA_CLAUDE_API_KEY`: used for actual inference when `/code` runs.

Also set the base URL:

- `SAMBANOVA_BASE_URL`: `https://api.sambanova.ai/v1`

For the **desktop app**, put them in `~/.claude/settings.json`, because the desktop app does not inherit shell variables:

```json
{
  "env": {
    "SAMBANOVA_API_KEY": "<SN_API_KEY>",
    "SAMBA_CLAUDE_API_KEY": "<SN_API_KEY>",
    "SAMBANOVA_BASE_URL": "https://api.sambanova.ai/v1"
  }
}
```

Restart the desktop app after editing it.

For the **CLI**, export the same three variables in `~/.zshrc` and launch from a fresh shell.

### 2. Install the plugin

In Claude Code:

```
/plugin marketplace add https://github.com/sambanova/sambanova-plugin-cc
/plugin install sambanova-plugin-cc
```

Then restart Claude Code, or run `/reload-plugins`.

### 3. Register the model

The plugin may ship with an outdated default. Register the model you want:

```
/model-info                 # catalogue, if the instance exposes it
/update-model <SN_MODEL>    # add to local registry; accept suggested sampling params
/list-models                # confirm
```

Always pass the bare model id to `/code` (for example `MiniMax-M3`), never `sambanova/MiniMax-M3`.

The executor model must support function calling, because `/code` drives file writes and shell commands through tool calls. Check that the model is listed under function calling for the instance before relying on it.

### 4. Verify

Run a small delegated task and confirm the output:

```
/code <SN_MODEL> ~/sn-smoke "Create a file called hello.txt containing the word ready, then stop."
```

Then check `~/sn-smoke/hello.txt` exists with the expected content. A run that only reports success without creating the file has failed.

---

## Known gotchas

| Symptom | Cause | Fix |
|---|---|---|
| 404 on the Messages endpoint | `ANTHROPIC_BASE_URL` or `SAMBANOVA_BASE_URL` ends in `/v1` (Option A) | Remove the `/v1` suffix for Option A. Keep `/v1` for `SAMBANOVA_BASE_URL` in Option B. |
| 401 Unauthorized | Key missing or wrong for this instance | Confirm the key with the curl check. Export it in the launching shell. |
| `/list-models` works, `/code` fails with model-not-found | `SAMBA_CLAUDE_API_KEY` missing (Option B) | Set it to the same value as `SAMBANOVA_API_KEY`. |
| Desktop app does not see the keys (Option B) | Desktop app ignores shell profile | Put the keys in `~/.claude/settings.json` and restart. |
| Background tasks hang silently (Option A) | `ANTHROPIC_DEFAULT_HAIKU_MODEL` unset | Set it to a model the instance serves. |
| Plugin install fails silently | Python 3.10 on `PATH` | Install Python 3.11 and make it the default. Delete the plugin's cached `.env` directory, then restart Claude Code to rebuild the venv. |
| Web search returns 400 (Option A) | Anthropic server-side web search is not supported on the Messages endpoint | Add a client-side web-search MCP server. |
| `/code` sub-agent cannot reach an MCP server | By design: `/code` has filesystem and shell only | Fetch the data in the main session, write it into `PLAN.md`, then delegate. |

---

## Known differences from the SambaNova guide

- The guide's examples point at `api.sambanova.ai`, which this file also uses.
- The guide names `MiniMax-M3` as the default model. Use whatever `<SN_MODEL>` your endpoint actually serves.
- The guide mentions only `SAMBANOVA_API_KEY` for the plugin. Option B also needs `SAMBA_CLAUDE_API_KEY`, and both must hold the same key value.
- The guide assumes shell variables reach Claude Code. For the desktop app they must go in `settings.json`.

---

## On-prem instances

To point the integration at an on-prem SambaNova instance instead of the cloud:

- Replace `https://api.sambanova.ai` and `https://api.sambanova.ai/v1` with the instance's base URL. Option A takes the base URL without `/v1`, and Option B takes it with `/v1`.
- Replace the key with the instance's key.
- Set `<SN_MODEL>` to a model the instance serves, and confirm it with the model-list checks above.

This path has not been tested against an on-prem instance.

---

## Demo: Claude plans, SambaNova executes

Once the integration works, this is the demo flow from the guide, with the same `PLAN.md` boundary.

1. In the Claude session, ask Claude to read a small project and write `PLAN.md` with a precise plan. Review it before handing it off.
2. Delegate execution:

   ```
   /code <SN_MODEL> <absolute-project-path> "Read PLAN.md and execute every step. After each step, list which acceptance criteria are now satisfied. Open index.html at the end so I can verify in the browser."
   ```

3. Verify in the browser or by running the project's tests. The executor never sees the Claude conversation, so `PLAN.md` must be self-contained.

Tips from the guide that still apply: use absolute paths for the working directory, tell the sub-agent to verify its own work, and do not pre-compute `git diff` or `grep` results in the prompt.

---

## Verification checklist

- [ ] Endpoint and key confirmed with the curl check (Option A) or `/list-models` (Option B).
- [ ] Model `<SN_MODEL>` appears in the instance's model list.
- [ ] A smoke prompt returns output from the SambaNova model (Option A), or `/code` creates the expected file (Option B).
- [ ] No keys were written into any project file or committed to version control.

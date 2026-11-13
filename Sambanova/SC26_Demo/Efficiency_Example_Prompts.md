# Efficiency example prompts

Author: Tim Clarke, SambaNova Systems
License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

Six prompts to try in a Claude Code session, grouped into script-shaped work and script-shaped work with reasoning, so you can compare how the session handles each one.

Before you start, read the notes at the end.

---

## Script-shaped work

These three ask for a batch job where nothing in any single item needs judgment — the Efficiency Directive alone should trigger.

### Example 1: Hugging Face batch pull

> I want to know the name, creator, usage and license information for the finetunes of gemma4 on Huggingface so I can do some data analysis.

**What is going on:** There are about 2,500 Gemma 4 fine-tunes, and each one needs the same few fields pulled from the Hugging Face Hub API. Nothing in any single lookup needs judgment. A session following the Efficiency Directives should say so, name the time and token cost of doing it one model at a time in chat, and offer a choice: write a script, or handle it directly. If you choose the script, it should write the script, give you the command, and ask whether you or Claude runs it.

**What to watch for:** A session that just starts fetching models one by one, without offering a choice, has not picked up the directive.

### Example 2: two-hop repo fetch

> I want you to pull every one of Burkardt-Fortran-90 example codes that is classified as linear-algebra. from https://github.com/Beliavsky/Burkardt-Fortran-90

**What is going on:** This looks like a GitHub repo browse, but the repo itself holds only index files (`README.md`, `code_list.md`, `todo.md`) — no code. The README groups folders under category headers (including "Linear Algebra," "Linear Algebra (Sparse)," "Linear Equations," and "Eigenvalues"), and each entry links out to John Burkardt's own site, where the actual `.f90` files live one hop further. The classification itself needs no judgment — it's already labeled by the README's own headers — but a session has to notice the two-hop structure (README → folder page → source files) and still offer the script-vs-manual choice before fetching anything. A handful of folders (e.g. `blas`) are umbrella pages with no direct `.f90` links; a good script reports those rather than guessing how far to follow them.

**What to watch for:** Whether the session investigates the repo's actual structure before assuming it can just "pull the folder" from GitHub, whether it still offers the script/manual choice despite the classification being free, and whether it flags the umbrella-page edge case instead of silently dropping or over-fetching it.

### Example 3: multi-org metadata pull, at scale

> I want a picture of the open-source footprint across the big DOE national labs — Argonne, Oak Ridge, Lawrence Livermore, and Sandia. For every repository in each of their GitHub orgs, pull the name, primary language, license, star count, and last-push date, broken out by lab, so I can tell which labs are most active on GitHub and which repos across all four are effectively abandoned.

**What is going on:** Same shape as a single-org repo-metadata pull, just repeated across four GitHub orgs (`argonne-lcf`, `ornl`, `llnl`, `sandialabs`) instead of one — roughly 1,900 repos total instead of ~150. Every field asked for comes straight off the GitHub API's repo-listing endpoint, and "effectively abandoned" is just a threshold on `pushed_at`, computed arithmetically, not inferred per-repo. The only real addition over a single-org version is a grouping key (lab) on the same arithmetic that was already happening.

**What to watch for:** Whether the session treats "expand to four orgs" as a reason to re-litigate the whole script-vs-manual choice from scratch, or recognizes it as the same shape just bigger and moves straight to scripting it; and whether it notices the constraint that actually changes at this volume — unauthenticated GitHub API rate limits (60 requests/hour) across ~20 paginated calls — without being told.

---

## Script-shaped work, with reasoning

### Example 4: Hugging Face batch pull plus per-item judgment

> I want the name, creator, usage and license information for the finetunes of gemma4 on Huggingface, and for each one, tell me its main purpose: Base the purpose on the model’s name and description, not just its tags.

**What is going on:** The data gathering is the same batch job as Example 1. The new part is the main-purpose column. Each model needs a judgment, reading its name and description and deciding what it is for. That is a question a language model is good at, but there are still thousands of models, so doing it one at a time in chat is still expensive. A session following the directives should recognize both parts: the batch data pull should become a script, and the per-model purpose step should be done by a model through a script that checks its output, rather than by Claude working through each model in chat.

**What to watch for:** Look for whether the session separates the two parts, offers the choice before writing anything, and plans to check the purpose labels, not just accept them.

### Example 5: two-hop repo fetch, plus per-file judgment

> I want you to pull every one of Burkardt-Fortran-90 example codes that is classified as linear-algebra from https://github.com/Beliavsky/Burkardt-Fortran-90, and for each file, write a one-line plain-English summary of what the routine actually does — read it from the source code itself, not from Burkardt's own description or the folder name.

**What is going on:** The fetch is the same two-hop pull as Example 2 (README → folder page → `.f90` files), still zero judgment. The new part is the summary: Burkardt's own page blurb and the README's folder grouping both exist already, but the prompt explicitly asks for a summary grounded in the code's actual content, which those sources don't reliably capture (a routine filed under "Linear Equations" might be an iterative solver, a direct factorization, or just an I/O helper — the label doesn't say). That means real per-file judgment, repeated across roughly 90 files. A session following the directives should split this the same way as Example 4: script the fetch, then route the per-file read-and-summarize step through a model via a script that checks its output, rather than reading ~90 Fortran files in chat.

**What to watch for:** Whether the session recognizes that "read from the source code" is a different, judgment-requiring ask than the tag-based classification in Example 2, whether it still offers the on-prem-delegation choice (try the on-prem model vs. a pilot sample vs. doing it directly) rather than just quietly reading all 90 files itself, and whether the verification step actually opens the code rather than trusting the model's summary at face value.

### Example 6: multi-org metadata pull, plus per-repo judgment

> I want a picture of the open-source footprint across the big DOE national labs — Argonne, Oak Ridge, Lawrence Livermore, and Sandia. For every repository in each of their GitHub orgs, pull the name, primary language, license, star count, and last-push date, and also tell me what scientific or technical domain each repo actually belongs to — climate modeling, plasma physics, HPC scheduling, machine learning infrastructure, and so on. Base the domain on the repo's name and description, not on GitHub's own topic tags, since those are sparse and inconsistent across these orgs.

**What is going on:** The data pull is the same four-org batch job as Example 3 — `argonne-lcf`, `ornl`, `llnl`, `sandialabs`, roughly 1,900 repos, name/language/license/stars/last-push straight off the GitHub API, zero judgment. The new part is the domain column. GitHub's `topics` field exists but is sparse and inconsistently applied across these four orgs, so it can't be trusted as the classification source the way Burkardt's README headers could in Example 2 — a session has to actually read each repo's name and description and decide what field it belongs to, same kind of judgment as Example 4's "main purpose," just applied to ~1,900 items instead of ~2,500. A session following the directives should split this exactly as before: script the metadata pull, then route the per-repo domain-classification step through a model via a script that checks its output, rather than reading through ~1,900 repo descriptions in chat.

**What to watch for:** Whether the session notices that `topics` isn't a reliable free classification here (unlike Example 2's README headers) and doesn't just read it as a tag lookup; whether it still offers the on-prem-delegation choice at this larger scale (~1,900 items is a meaningfully bigger ask than Example 4's or Example 5's); and whether the verification step checks for something concrete (e.g. flagging domain labels that share no words with the repo's own name/description) rather than trusting the model's labels outright.

---

## Notes before you start

**Claude tends to just do the work.** Left to its own default, Claude will often start fetching or classifying immediately, one item at a time, without offering a choice. You will probably need to remind it to follow the Efficiency Directives. A simple "Please follow the efficiency directives" early in the session is usually enough.

**These prompts rely on the directives.** They only work as intended if the session knows the directives. A new session does not know them unless the project's `CLAUDE.md` includes them. The Efficiency Directives Primer (`Efficiency_Directives_Primer.md`) explains how to add them, and the session can ask you to save them when it first reads the primer.

**Results will vary.** Two sessions can take different routes to the same answer. What matters is whether the session notices the batch pattern and asks before doing the work.

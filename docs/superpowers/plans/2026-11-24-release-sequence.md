# Classic compatibility patch and 3.0 migration releases

This is the execution order as of 2026-11-24. It updates the [August implementation plan](2026-08-20-two-step-upgrade-path.md). The [upgrade design](../specs/2026-08-20-two-step-upgrade-path-design.md) and the four owner decisions in the finalized November review govern the migration. The full findings are on this workstation at `/home/seth/dev/ember-remodal/.agents/qc/2026-11-18-deep-review.md`. Run Beads commands from `/home/seth/dev/ember-remodal`, where the live tracker resides.

## Release map

| Bead | Work | When it can start |
| --- | --- | --- |
| er-cct.1 | Finish the 2.18.1 compatibility evidence on `fix/2.18.1-compat` | Now |
| er-cct.2 | Publish 2.18.1 on `latest` | er-cct.1 verified and Seth approves this release |
| er-f0t.6 → er-f0t.5 | QC Grouping 1 on `2.x`, including the ten warning tests | er-cct.1 verified, independently of patch publication |
| er-f0t.7 | QC Grouping 2 on `pending/release-prep`, fix the demo examples | Grouping 1 verified, including er-f0t.5 |
| er-f0t.8 | QC Grouping 4 on `pending/release-prep`, finish master housekeeping | Grouping 2 verified |
| er-f0t.9 | Deploy Pages and verify a deep link | All three QC groupings verified and Seth approves the deploy |
| er-f0t.2 | Publish 2.19.0 on `latest` | Pages verified, patch publication resolved, the beta candidate verified, and Seth approves the paired release |
| er-f0t.10 | Publish 3.0.0-beta.0 on `beta` | Straight after 2.19.0 verifies, in the same release window |
| er-1u2 | Grouping 3, finish demo parity against the original acceptance criteria | After the releases |

Owner decision, 2026-11-24: the `v3-available` warning keeps its wording ("ember-remodal 3.0 is available"). To keep that true, 2.19.0 and 3.0.0-beta.0 publish in one release window. 2.19.0 does not go out until the beta candidate is verified and ready to follow immediately.

The independent patch is epic er-cct. The migration stays under er-f0t. Its completed feasibility, readiness-prompt and guide beads remain historical evidence. er-f0t.2 closes at verified publication, so er-f0t.6 tracks the engineering work that has to finish earlier. If Seth decides to skip the patch publish, record that disposition on er-cct.2 before promoting 2.19. An older patch published later must never move `latest` backwards.

## 2.18.1 implementation handoff

Start in the **main checkout** and claim `er-cct.1`. Locate `fix/2.18.1-compat` with `git worktree list`; the branch is backed up on origin and its original worktree is temporary. The verified starting commit is `3b6f174`, based on `v2.18.0`. It already supplies the wormhole runtime dependency, fixes close-before-open, names the native close button and sets both version locations. Preserve the classic API, string actions, service properties, RSVP results and existing toolchain floors.

The original probe apps, their tests, the logs and the tarballs were built in `/tmp/remodal-patch-s7ROV7`, which the system empties after ten days. A copy is in the main checkout at `.agents/qc/2.18.1-consumer-probes/` (local and git-ignored, like the review), with a `SHA256SUMS` file. It holds `modal-consumer/` (Ember 2.18.2), `floor/` (Ember 2.3.2), `consumer3/` (Ember 3.28.12), the six Ember 2.3.2 runtime files, the jQuery 2.2.4 tarball and the packed candidates.

1. Port the successful packed-app checks into the branch as a repeatable command. The ember-audio v1 backport's `scripts/test-consumer.sh` (`origin/fix/64-v1-backport` in ember-audio, commit `e103253`) illustrates how to generate an independent app, install a tarball and verify the installed code. Use the copied probe apps as source material and commit what the command needs as fixtures on the branch, outside the tarball. The committed command must run from a clean checkout with no dependency on this workstation or a sibling repo.
2. Run headless Chrome on the actual packed candidate at the three previously observed configurations.
   - **Floor, Ember 2.3.2.** The probe used Ember CLI 2.18 with the Ember **2.3.2 runtime and matching compiler**, plus jQuery **2.2.4**. It is the Ember CLI 2.18.2 blueprint app after two swaps inside `node_modules`. Six files in `ember-source/dist` (`ember.debug.js`, `ember.prod.js`, `ember.min.js`, `ember-runtime.js`, `ember-template-compiler.js`, `ember-testing.js`) were replaced with the builds from `https://github.com/components/ember` at tag `2.3.2` (`98e3bff9dbbbb7907b8e5ada7483ba0c16c18481`), because `ember-source` is not on npm before 2.11. `jquery/dist/jquery.js` was replaced with the file from `jquery@2.2.4`. Both `package.json` files still report 2.18.2 and 3.3.1 afterwards, so only the in-browser `VERSION` and `$.fn.jquery` assertions prove what ran. The committed command fetches both by pinned commit and version and checks them against recorded SHA-256 values before swapping. In the probe, `ember.min.js` was a copy of `ember.prod.js` and `jquery.min.js` stayed at 3.3.1. Decide whether a production build of the floor is in scope, and cover both files if it is.
   - **Unswapped, Ember 2.18.2.** Run the same app once before the swap. It is the one consumer with an unmodified runtime, and the branch README already cites it.
   - **Upper, Ember 3.28.12.** The probe used CLI **3.28.6**, Ember **3.28.12**, `@ember/jquery` and enabled jQuery integration.

   Pin and assert the resolved runtime versions in every consumer. Install only the host prerequisites. Let the package supply `ember-wormhole`. Exercise the yielded block trigger, real open/close state, service access and a close-before-open promise resolving to the component. The probe tests are a starting point, not the finished check: none asserts that the close-before-open promise resolves to the component, and the 3.28 test asserts no versions. They also ran against `rc.tgz`, whose addon code matches the final pack but whose README and test script do not. Confirm the relevant checks catch the original defects, using 2.18.0 or a controlled omission.
3. Run the three consumers in CI alongside the existing full addon suite on Ember 2.12.2, 2.16.4 and 2.18.2. CI packs the tarball once, every consumer installs that file, and the job uploads it as a workflow artifact and prints its SHA-512 integrity. Verify production build and tarball contents. The candidate has 20 files under both npm 6.13.4 and npm 11, one fewer than 2.18.0 because `yarn.lock` is no longer packed. Replace the README's open-ended compatibility table with the tested configurations, distinguishing full-suite and consumer evidence, Node/CLI setup and the Ember 3.28 deprecations. The README names only configurations CI runs. Keep unverified FastBoot, browser and Ember 4+ claims out of the tested range.
4. Record SHA, resolved versions, CI link, pack contents, the tarball's integrity hash, the CI artifact that holds it and results in er-cct.1. Once green, close it, surface er-cct.2 for a separate publish decision, and use the QC handoff below. Patch publication is independent of Pages. The old 2.18 demo stays live through prep.

## QC handoff for a fresh session

Use Fable 5.2 as recommended by the reviewer for the Ember 2.18 property work. Invoke the following from `/home/seth/dev/ember-remodal` once er-cct.1 is verified. The report is local to that checkout. If resuming, inspect the cycle state there and continue the first incomplete grouping.

```text
/qc

Use the finalized .agents/qc/2026-11-18-deep-review.md in the main
ember-remodal checkout and docs/superpowers/plans/2026-11-24-release-sequence.md
on pending/release-prep. Use .agents/qc/ for cycle state. The findings and
owner decisions are final. Skip a new deep-review. Read er-cct.1 for the
verified patch commit and consumer evidence. A pending er-cct.2 publish
decision does not block this session.

Work one grouping at a time. Record each verification on its existing bead.

1. Grouping 1, er-f0t.6 and er-f0t.5. Work in ~/dev/ember-remodal-2x on
   2.x, using Node 8.17.0 and yarn 1.22.19. Install with yarn install
   --frozen-lockfile --ignore-engines --ignore-optional --non-interactive.
   Use the pinned Node for builds, tests and pack. Carry the patch fixes,
   regression coverage and packed-consumer checks forward selectively.
   2.x already has its own close-before-open warning (Ember.Logger.warn)
   and native close title, from eleven commits that sat unpublished on the
   old master (v2.18.0..df25509, a range the review did not cover; its only
   functional changes are those two). Keep the 2.18.1 warning
   implementation so 2.19 does not change it again. The title is the same
   on both branches. The v3-available wording is settled: leave it as
   written. Set 2.19.0 in package.json and vendor/ember-remodal/register-version.js.
   For A1, guard warning output and config access so a warning cannot break a
   modal. For A2, use the decided real-property accessor and prove native
   .modal, get('modal') and set('modal', x) preserve 2.18 behavior on Ember
   2.18. For A3, keep detection and correct the message: the service property
   lookup goes away, while open()/close() on the promise result still work.
   Preserve all warning IDs, anchors and opt-out behavior. Remove each of the
   ten warning calls in turn, see a relevant test fail, restore it and record
   the ten-row mutation table. Verify suite, pack and the three consumer configurations.

2. Grouping 2, er-f0t.7. On pending/release-prep fix the install tag, CSS
   import, private imports in displayed/copied examples, sample dialog-state
   assertion, and real CSS hooks. Follow the report for C6–C10 and structural
   assertions. C3 is settled: rewrite #src specifiers at display time.
   Verify tests, demo build, copyable examples and tarball exclusion.

3. Grouping 4, er-f0t.8. Follow the report for audit/lint, clean-tree and
   docs housekeeping. Verify pnpm lint, tests, published-package checks,
   pack contents, clean release tree and warning anchors. Time B5 to the
   actual registry transitions, including 2.18.1 if it ships. Apply current
   authoring preferences to prose; page-authoring applies to demo pages.
   Leave Grouping 3 on er-1u2 for after the releases.

Keep master-bound work on pending/release-prep. Ordinary 2.x pushes are
fine. A master push triggers Deploy demo and push-dist. Stop after reporting
the tested commits, evidence and separate readiness verdicts for Pages,
2.19.0 and 3.0.0-beta.0. Seth approves each outward action. 2.19.0 and the
beta are presented together because they publish in one release window.
Leave npm publication, tags, GitHub releases, Pages settings, deploy reruns
and integration into master for those decisions.
```

## Release-day verification

For each approval, present the exact branch, SHA, artifact or deploy, and intended effect. Recheck current registry tags and whether the target version exists. If a previous attempt already published it, verify integrity before resuming the remaining steps.

Seth runs `npm login` and every `npm publish` in his own terminal. This workstation is not logged in to npm, and an agent shell cannot complete an interactive login or a one-time code. The agent prepares the exact command block and verifies the registry afterwards. For the two classic releases, publish the tarball file that CI built and tested on the approved commit: download the workflow artifact, confirm the recorded integrity hash, then `npm publish <file>`. Never publish a fresh pack of a working tree. The npm 6 that ships with Node 8.17 may not support the current login flow. Any current npm can publish the file.

- **2.18.1** comes from `fix/2.18.1-compat`. Verify the published tarball and Git tag against the approved candidate, and `latest=2.18.1`. The release notes list the fixes and the two visible differences from 2.18.0: the native close button gains `title="Close Modal"`, an English hover tooltip, and the tarball no longer carries `yarn.lock`. Update the exact-version lines (`README.md:107`, `MIGRATION.md:156`) on `pending/release-prep`. That satisfies er-cct.2, and the lines reach master with the approved integration.
- **2.19.0 and 3.0.0-beta.0** publish in one window, 2.19.0 first. Present both candidates in one approval request and start only when both are verified. If the beta publish fails after 2.19.0 is out, report it at once. `latest` stays at 2.19.0.
- **Pages** uses the tested modern commit. Include master integration and its automatic workflows in the approval request. Switch the source to Actions, run the intended deploy, and verify the live homepage and a direct deep link. The demo's beta installation command becomes usable when the beta publishes.
- **2.19.0** comes from `2.x`. Verify both version locations, the packaged consumer smoke, live migration anchors, the intended Git tag and `latest=2.19.0`.
- **3.0.0-beta.0** comes from the verified modern package. Confirm the prepublish clean-tree check and pack contents, publish to `beta`, verify the intended Git tag and both registry values (`beta=3.0.0-beta.0`, `latest=2.19.0`). Update unreleased/date wording at publication.

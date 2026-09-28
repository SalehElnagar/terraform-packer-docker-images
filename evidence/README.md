# Recorded local evidence

These are observations from the local run on 2026-09-27 (America/Toronto).
Tool versions and source/screenshot hashes are in [manifest.json](manifest.json).
No cloud deployment, hosted CI run, or registry push is claimed.

| Case | Observed result |
|---|---|
| Terraform baseline | HTTP 200; version one; expected runtime settings |
| Edit without rebuilding | Source version two; running response still version one |
| Terraform rebuild | Image changed; HTTP 200; version two |
| Omitted content trigger | HTML changed; no-op plan; HTTP still version one |
| Initial Packer image | Build succeeded; runtime exited 2 with the inherited shell entrypoint |
| Repaired Packer image | Explicit Python entrypoint; HTTP 200; ten runtime checks passed |

The JSON files contain selected, sanitized observations rather than raw Docker
inspect output, Terraform state, plans, or build logs. Image configuration IDs
identify local image configurations; they are not registry manifest digests.

## Article screenshots: actual tool output

The article uses two browser screenshots of sanitized output captured during the
original local execution. The complete selected text is available beside each
image. These are GitHub views of recorded stdout, not newly executed terminal
sessions. No build or apply was repeated to make these screenshots.

![Terraform creates the baseline and replaces both resources after the HTML edit.](screenshots/terraform-apply-output.jpg)

[Terraform output](output/terraform-apply-output.txt): all original output lines
from the baseline and rebuild apply, with local resource IDs redacted and two
editorial section headings added.

![Packer provisions the page, commits the image, and creates its local tag.](screenshots/packer-build-output.jpg)

[Packer output](output/packer-build-output.txt): selected lines in original order;
temporary paths shortened and IDs and pull progress omitted. The tag is local.
It is not evidence of a registry push.

[Provenance](output/provenance.json) records the source-log hashes and exact
editing rules. [Screenshot audit](screenshot-audit.json) records the capture
revision and hashes. The older JSON screenshots remain in `screenshots/` for
history, but are no longer article figures. Runtime assertions remain in the
JSON files as supporting evidence.

## Archived original browser captures

### Terraform baseline

![The Terraform-created container serves version one.](screenshots/terraform-version-one.png)

Captured from `http://127.0.0.1:18080/` after the baseline apply.

### Source edited, image unchanged

![The existing container still serves version one after the source file was edited.](screenshots/source-edited-still-version-one.png)

Captured from the same endpoint after editing the source and before applying a
new build. The screenshot alone does not prove the source changed; the paired
observation and input fixture supply that context.

### Terraform rebuild

![After the reviewed rebuild, the container serves version two.](screenshots/terraform-version-two.png)

Captured from the same endpoint after image and container replacement.

### Omitted-trigger case

![The negative-case container still serves version one.](screenshots/no-trigger-version-one.png)

Captured from `http://127.0.0.1:18082/`. The associated JSON records the no-op
plan after changing its source to version two.

### Packer runtime

![The corrected Packer image serves version one.](screenshots/packer-version-one.png)

Captured from `http://127.0.0.1:18081/`. The runtime verification checks the
process and settings that a page screenshot cannot establish.

The captures are cropped browser screenshots, not generated examples or
reconstructed terminal output. They show exactly the served page. They do not
prove that every possible behavior works.

## Runtime verification report

![Ten runtime checks pass in the committed report.](screenshots/runtime-verification-report.png)

Actual browser capture of the report generated against the running Terraform container.

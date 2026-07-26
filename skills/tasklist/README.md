# /as:tasklist

Maintains one canonically resolved `TASKS.md`. By default each Architecture Studio project owns its register. A studio may instead opt into portfolio mode, where one studio-root register is authoritative and each task carries a Project ID.

## Usage

```text
/as:tasklist list
/as:tasklist add Coordinate reflected ceiling plan with electrical
/as:tasklist update T0012 owner: Priya
/as:tasklist complete T0012
/as:tasklist cancel T0014 reason: superseded by T0018
/as:tasklist import meetings/YYYY-MM-DD-owner-review.md#A3
```

`/as:tasklist` supports list, add, update, complete, cancel, and confirmed import. Imports are previewed and selected item-by-item. When a normalized source path and item—or the same canonical conversation token—already belongs to a task, the skill offers to link, update, or intentionally create a separate task instead of duplicating it silently.

With no arguments, `/as:tasklist` lists the current project. Project context requires `PROJECT.md`; generic folders and git roots are never treated as projects. From a studio root, the skill reads `STUDIO.md` and offers its eligible projects plus **All projects**. In default project mode, All projects is a read-only merged view with qualified IDs such as `2401:T0007`. In portfolio mode, it is the unfiltered studio register.

Task IDs are never deleted, reused, or renumbered. Updates preserve provenance and append lifecycle history. A malformed register is preserved and blocks mutation until the user approves a repair.

Project and portfolio registers are never simultaneously writable for the same studio. Moving a populated studio between modes requires an explicit migration; empty studios can switch after a preview and confirmation. The skill is harness-neutral and independent of `/as:workplan`.

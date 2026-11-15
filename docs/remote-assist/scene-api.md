# The scene API: how the guide builder and the 3D view talk

The dashboard has two halves. The **3D view** of the scanned room is Max's (`dashboard/src/scene/`). The **guide
builder**, where the expert writes the steps, is Laura's (`dashboard/src/guide/`). `dashboard/src/scene/api.ts` is the
list of things the guide builder can ask the 3D view to do, and what it hears back.

## Decision 1: who keeps the steps? (decided)
**Question:** when the expert builds a guide, should the steps live in one place, or should both halves keep a copy?

**Decision (Max, 2026-11-14): one copy, in the guide builder.** The guide builder hands the 3D view a whole step
("show these objects"), and the 3D view draws exactly that. When the expert drags something in 3D, the 3D view
reports it ("object o3 moved here"). The guide builder updates its copy and hands the step back.

**The alternative we didn't pick: both halves keep a copy** and send each other changes one at a time ("add a
screw", "move the screw", "delete the screw"). Each call is simple to read, but the two copies have to be kept in
step by hand. If one message is missed or arrives out of order, the 3D view shows something the step list no longer
has, and nothing notices.

**Why:** one copy can't disagree with itself. It also matches the protocol, which already sends the phone the whole
guide on every edit (`guide.set` in `contracts/protocol.ts`), and it means the guide builder can be tested without
any 3D at all.

**What would make us revisit it:** a step with so many objects that redrawing the whole step on every edit is
visibly slow. That's unlikely: a step has a handful of objects.

## Decided: nothing is placed before calibration (Max, 2026-11-15)
**Question:** every object needs an address in 3D, measured from some fixed point.
- **The phone and the protocol already measure from the printed marker** (`contracts/protocol.ts`, decided by
  Ahmed). So the addresses stored in a guide are "from the marker", and the guide builder copies them from the 3D
  view without any maths.
- **The scan has its own random fixed point**, wherever Scaniverse put the middle, and it changes on every rescan.
  The 3D view converts scan addresses to marker addresses once the expert has clicked the marker's corners
  (Max's task 3, calibration).

The question was what happens **before** calibration:
- **A, nothing can be placed until calibration is done.** Safe: every saved address is right. Costs the expert one
  step up front.
- **B, placing works straight away using scan addresses, and they are converted once calibration is done.**
  Smoother, but a guide built before calibration holds addresses the phone would read wrongly, and a rescan breaks
  them.

**Picked: A** (Max, 2026-11-15, as Ahmed recommended). Until the scan on screen is calibrated, `pickPoint()`
resolves to null and no objects are drawn, so no address measured from nothing can reach a phone. Each scan keeps
its own calibration, saved through the relay, so the step costs four clicks once per scan, not per session.

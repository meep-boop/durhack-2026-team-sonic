# Remote Assist: hands-free AR guidance from a 3D copy of the room

A technician wearing a Quest 2 is guided to the exact part on a panel, hands-free. A phone video of the panel becomes a
3D Gaussian splat (trained on the Dawn supercomputer). A remote expert clicks parts in that splat, and the headset
highlights them over the real panel, with an arrow when the part is out of view.

**Status:** plan only, no code yet. Written 2026-11-14 by @max from the planning session before the event. Nothing
here is a locked decision until the team agrees it at kickoff; items marked **proposed** are open.

| File | What's in it |
|---|---|
| [architecture.md](architecture.md) | Components, data flow, coordinate frames and calibration, message protocol |

## The demo: a race a video call loses

- **The set:** a portable foam-board "ISS maintenance panel" (about A1) covered in identical switches, bolts and cable
  ports, with a Raspberry Pi mounted on it. Its 40 identical GPIO pins are the hardest target. We scan it once, so the
  demo works at any table.
- **The race:** two judges get the same task, e.g. "flip breaker 14, then move the jumper to GPIO 17". Judge A is
  guided over a normal phone video call. Judge B wears the Quest. Time both on a big screen.
- **The reveal:** the expert laptop shows the splat, with judge B's head and hands as an avatar moving inside it. No
  video was sent.
- **Comms blackout / Mars mode:** switch on a 20-second delay, or cut the link. Video becomes useless, but steps the
  expert marked in advance still guide the technician.

**Pitch (3 min):** a 20 s hook (Mars is minutes away by radio; a data centre has thousands of identical cables) → a
90 s race → a 40 s reveal ("trained on the Dawn supercomputer") → 30 s on uses: ISS maintenance, trading-firm data
centres, Northumbria's new space centre.

## Why it isn't just a video call

- The expert points at a **saved 3D model**, including things the technician isn't looking at. Existing tools (PTC
  Chalk, TeamViewer Frontline, Scope AR) annotate live 2D video.
- Microsoft Dynamics 365 Remote Assist stops working on 31 Dec 2026 with no named successor.
- Precedent in space: NASA's T2AR (HoloLens, ISS treadmill maintenance) and ESA's mobiPV gave astronauts AR or
  remote-expert support. Instructions prepared in a saved 3D model still work under Moon or Mars comms delay.

## Challenge fit (from the opening ceremony slides)

The overall theme is **Composition** (art, music, mixing ideas). Judging for everyone: creativity and innovation,
technical execution, research and learning, polish.

| Challenge | Fit | What we'd need |
|---|---|---|
| **Marshall Wace: "New Worlds"** (creativity, technical complexity, presentation) | Strong | Nothing extra. Stepping into a 3D copy of a space-station panel is the pitch |
| **Neptune North: actors that keep working when comms fail** (£1,000 first prize) | Good with additions | **Proposed:** blackout mode (the Quest caches the procedure and syncs when back) and a second technician on an iPhone splitting steps independently |
| **Accenture: redesign a frustrating process with AI/LLMs** | Good with additions | **Proposed:** AI auto-labelling of every switch and port, so the expert types "port C7" |
| **RS: sense, analyse, respond** (Arduino UNO Q + camera mandatory, hardware library) | Medium | **Proposed:** UNO Q and camera on the panel detect the switch actually flipped, tick the step and warn on a wrong one |
| Consultancy on slides 25–29: "connect things that usually aren't" (Pi Pico kits) | Loose | Expert ↔ technician, VR ↔ AR, supercomputer ↔ headset |
| Overall theme: Composition | Weak | Angle: mixed reality composites digital content onto the real world |
| SGX FX, P&G, QRT | None | Skip |

Suggested priority (**not decided**): Marshall Wace and Neptune North first, then Accenture; RS only if an UNO Q is
borrowed early. Check whether Devpost allows entering several sponsor challenges.

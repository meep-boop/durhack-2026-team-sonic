# DurHack 2026: rules, judging and context
*For Team Sonic. Fill it at kickoff from the event's own pages: paste the rules, schedule and judging criteria into
the chat and say "fill EVENT.md". Where two sources disagree, write both down and plan for the stricter one. Our own
spec lives in `PROJECT.md`.*

**Source for everything filled in below:** `DurHack26_CONTEXT.md`, a notes file in Ahmed's working folder (not in
the repo), written Sat 14 Nov 18:15 from the opening ceremony slides and speaker notes. Nobody has checked it
against the Devpost page yet. Gaps are marked _not stated_.

## 1. Event essentials
- **Where:** Durham, Teaching and Learning Centre (TLC). **Theme: COMPOSITION** ("explore art, music and tech",
  "idea mixing and trying new combinations").
- **Organisers / sponsors:** DurHack. Sponsors with challenges: QRT, RS Group × Arduino, Marshall Wace, Neptune
  North, Accenture, SGX FX, P&G, Waterstons, Hackathons UK, MLH.
- **Where submissions go:** Devpost, submitted by: _not decided_
- **Team size, and whether everyone must be registered on the platform:** maximum 4. Registration: _not stated_
- **Tracks / sponsor challenges we're entering:** Neptune North, Accenture, Marshall Wace, RS (decided by Ahmed,
  2026-11-14). **The slides don't say how many challenges one project may enter.** Ask an organiser.
- **Prizes:** overall 1st a portable monitor and electronic keyboard; 2nd a £100 Amazon voucher and Polaroid camera;
  a Spirit of the Dino award. Sponsor prizes are in §4.

| When | What |
|---|---|
| Sat 14 Nov, 12:00 | Hacking starts |
| Sun 15 Nov, 12:00 | **Submission deadline** (Devpost) |
| Sun 15 Nov, from 12:30 | Judging: judges visit tables |
| _not stated_ | Closing ceremony |

Other schedule notes: midnight pizza; sleeping area TLC123.

*Copy the deadlines into `PROJECT.md` → NOW → Clock, which is where the team plans from.*

## 2. Submission checklist
- [ ] Title and short description
- [ ] Demo video (length limit: _not stated_), with captions if allowed
- [ ] Repo link (public by the deadline? _not stated_), with a README judges can follow (`pitch` skill)
- [ ] **AI tools credited on Devpost** (a stated rule, §3)
- [ ] Deck / slides, if asked for
- [ ] Live demo link or a way to run it
- [ ] Every member added to the submission
- [ ] Tracks and sponsor challenges ticked
- [ ] Open-source libraries and data sources credited, and a LICENSE if the event wants open source
- [ ] `bash scripts/submission-check.sh` passes, and the `context` branch is deleted if the repo goes public

## 3. Rules that bite
- **Code written during the event?** Yes: code must be written during the event, and code from before it can't be
  used. Libraries are normal. **Unclear for us:** the team kit (`scripts/`, `kit/`, the skills) was adapted from an
  earlier datathon. It's tooling, not product code, but ask an organiser if it worries anyone.
- **AI tool policy:** allowed, and **AI tools must be credited on Devpost.** We use Claude Code throughout, so say
  so there and in the README (`pitch` skill). Not in commit trailers (CLAUDE.md §7).
- **Licences / open source:** _not stated_
- **Data and privacy:** _not stated_. Ours: the scan and the live camera show a room, so keep people out of both.
- **Platform / sponsor terms of use:** the RS challenge makes an **Arduino UNO Q, a camera and USB hubs mandatory**.
- **Conduct:** _not stated_

## 4. Judging
| Criterion | Weight | What 9–10 looks like |
|---|---|---|
| Creativity and innovation | _not stated_ | |
| Technical competence and execution | _not stated_ | |
| Research and learning | _not stated_ | |
| Polish and completion | _not stated_ | |

- **What judges check:** they visit each table from 12:30 Sunday, so the demo is live and in person. The rest is
  _not stated_.
- **Sponsor prize criteria** (the four we're entering):
  - **Neptune North, "Actors work better together":** systems working together on a common goal in a distributed
    way, each actor operating without instructions from a central hub when communication is unreliable. Criteria:
    working towards a common goal; independent decision-making; resilience when communications fail; something
    you're excited about. Prize: a £1,000 voucher; runner-up mechanical keyboards.
  - **Accenture:** find a frustrating process people accept as "just the way things work" and redesign it with
    modern AI and LLMs. Criteria include **responsible AI**. Prize: Sony headphones, keyboard and mouse, bag.
  - **Marshall Wace, "New Worlds":** "something that opens a door to the unexplored". Judged on creativity,
    technical complexity and presentation. Prize: a VR headset.
  - **RS Group × Arduino:** "an intelligent system that can sense, analyse and respond to the real world":
    capture data, analyse sensor inputs, make a decision, trigger an action. Mandatory hardware above. Prizes for
    1st to 3rd.
  - Not entering: QRT ("Tagged" and the CTF), SGX FX, P&G, Waterstons, Hackathons UK, MLH. Their briefs are in the
    source file.
- **A fit to watch:** Neptune North asks for several actors with **no central hub**. Our relay is a hub. The pitch
  has to show the phone deciding for itself once the link drops, or the fit is weak.

## 5. What wins
*Filled by `idea-forge`: patterns from past winners at this event or similar ones, with the evidence in
`research/ledger.md`. Patterns, never ideas: original work only.*

## 6. Platform and sponsor tech
- **What we're given:** the RS Product Loan Library on the top floor (student ID and table number), which may
  supply webcams, USB-C hubs and sensors; a 3D printer (queue unknown, a small print takes 1 to 2 hours). Dawn
  supercomputer access was in Max's plan, but **we have no Dawn access** (Max, 2026-11-14). The team has its own
  NVIDIA DGX Spark instead.
- **What the team already has** (per the source file): an **Arduino UNO Q**, an Arduino Nicla Vision (a camera
  board), a Raspberry Pi Pico W, an M5Stack Cardputer, an Arduino Sensor Kit, Modulinos, a servo and motors. Not
  owned: a USB webcam, a micro-USB data cable. **For RS** (2026-11-14): the Nicla Vision is our camera, and the RS staff
  confirmed it counts; Ahmed has a USB-C hub.
- **Constraints:** **hall Wi-Fi will be slow; use a phone hotspot.** A paper printer's availability is unknown,
  which matters for the marker. The UNO Q has forum complaints about serial output to a PC and analog input: ask
  the RS and Arduino staff. A native iPhone app needs a Mac with Xcode.
- **Where the keys live:** _a location only, never a value_

## 7. How we chose the idea
*The `idea-forge` summary: the candidates, how each scored, and why the winner won.*

## 8. Support
- **Mentors / help desk:** RS and Arduino staff are at the event for UNO Q questions. Others: _not stated_
- **Channels:** _blank_

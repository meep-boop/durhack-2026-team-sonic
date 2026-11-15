## Inspiration
My younger brother video-calls me whenever his computer plays up, and he never points the camera at the right
thing. "No, the other cable. Lower. No, *lower*." Ten minutes in, nothing's fixed.

At work I'm at an MSP, looking after IT for lots of different organisations. I once had to help a business manager
through a network failure at their [TODO: finish this: where it was, what went wrong, and what made it hard to fix
remotely]. Same problem, higher stakes. The expert knows exactly which screw, which port, which cable, and has no
way to point at it. And when the network itself is what's broken, the video call is the first thing to go.

So we asked: what if the expert could put the answer *on* the real hardware, through the phone, and it kept
working with no signal?

## What it does
Sonic Assist gives someone on site step-by-step 3D instructions on their phone. A remote expert builds them from a
3D scan of the room.

- **The person on site** points an iPhone at the hardware. Each step is drawn over the real thing: a box around the
  part, a small animated model showing what to do (a screw unscrewing, a hand pulling) and one plain instruction.
  They do it and tap **Next**.
- **The remote expert** gets a dashboard with a 3D scan of the room. They click the four corners of a printed
  marker to line the scan up with the real world, then build the guide by placing objects on the scan.
- **On a live call**, the expert can click on the phone's video and the mark lands on the real part, or drag a box
  around an area so everything else dims. Steps are read aloud and the call is transcribed live.
- **When the network drops**, the phone carries on, because it already has the whole guide. Taps queue up, survive
  the app being closed, and sync when the signal's back, stamped with when they really happened. None is lost or
  counted twice. The expert sees "Offline 0:42", then "Back online" and how many steps were done in the meantime.
- **A camera rig checks the work.** An Arduino UNO Q with a Nicla Vision camera watches the open laptop and shows
  ✓ or ✗ on both screens: is the SSD in its bay or not?

Our demo is a real job: swapping the SSD in a teammate's Dell laptop. That means screws, a cover, and a part out
and back in.

## How we built it
Four parts, four people, one message format.

- **iPhone app** (Salman): native Swift with ARKit and RealityKit. ARKit tracks a printed 180 mm marker and every
  step is pinned to it. The live call is WebRTC. ElevenLabs reads the steps aloud and transcribes the call, and the
  API key never leaves the phone: it hands out single-use tokens instead.
- **Expert dashboard** (Max and Laura): Vite, React and TypeScript, with three.js and Spark to show Gaussian splat
  and mesh scans from Scaniverse. Max built the 3D view, calibration, clicking to place, AI part labels and the live
  status strip. Laura built the guide builder, the printed marker and the 3D models. One Python script makes every
  model in both glTF and USDZ, so the phone and the dashboard never drift apart.
- **Relay** (Ahmed): Node and `ws` on a laptop, over a phone hotspot, because venue Wi-Fi is slow. It passes
  messages on, saves its state to disk so a restart loses nothing, and sends back a receipt for every tap. Every
  part speaks one TypeScript contract, and the Swift app mirrors it by hand.
- **Rig** (Ahmed): the Nicla Vision looks for a bright sticker on the SSD, and the UNO Q reads it over USB, tells
  the relay, and shows ✓ or ✗ on its LED matrix.
- **AI-made props** (Max): Pixal3D on our team's NVIDIA DGX Spark turns one phone photo of a tool into a textured,
  life-size 3D model.

We built all four in parallel from the first hour. Each of us worked against fake versions of the others (a fake
phone, a fake expert), so nobody sat waiting.

**How we used AI.** All four of us wrote code with Claude Code. We ran it from one shared rulebook: Claude writes the
code, but it stops at every design decision (what gets saved, message shapes, what happens offline, any new
library) and hands it to a person with options and a recommendation. Inside the product, Claude suggests part labels
on the scan, marked **AI** and editable. ElevenLabs does the voice and transcript. Pixal3D makes the props, labelled
"AI-generated from a photo".

## Challenges we ran into
- **Lining a scan up with the real room.** This was the whole game. The phone, the scan and the dashboard each have
  their own idea of where zero is and how long a metre is. We made the printed marker the one shared origin: every
  position travels as metres from the marker's centre. Our first scan didn't have the marker in it, so nothing
  could be placed and the boxes hovered in mid-air. We rescanned.
- **"Why is it on the other side of the room?"** On Sunday morning the guide's marks showed up across the room on
  the phone. Instead of guessing, we listened in on the relay and checked the positions leaving the dashboard. They
  were right, so the fault had to be on the phone. Our lead suspect is that the phone anchors to the *first* marker
  it sees, so a second copy (like the one inside the scan on the dashboard's screen) drags the whole guide over to
  it. [TODO: say whether it's fixed by submission time]
- **A camera that froze.** The phone's camera view kept freezing. Five fixes in, there was still no confirmed cause,
  so we went back to a plain build that worked and brought features across one at a time.
- **A licence we couldn't use.** Our first pick for AI props was Hunyuan3D, but its licence excludes the UK, and
  we're in Durham. We switched to Pixal3D (MIT licence) and built it in a home folder on a shared GPU box with no
  Docker or admin rights.
- **Hardware that disagreed with its docs.** The Nicla Vision only sends over USB when DTR is set, the opposite of
  what our source said. It also can't lock its white balance, so moving a lamp changes what it sees.
- **Plans that met reality.** The supercomputer access we planned on never came, so scan training moved to our DGX
  Spark. Expo couldn't give us ARKit directly, so the app went fully native. The demo moved from a network cupboard
  to a laptop SSD swap we could actually bring to the table.

## Accomplishments that we're proud of
- Four separate pieces (a phone app, a web dashboard, a relay and an Arduino rig) talking through one shared
  contract, built by four people in parallel in 24 hours.
- Offline really works on the phone. Turn Wi-Fi off, tap through steps, close the app and reopen it on the same
  step, reconnect, and every tap syncs exactly once, with the time it really happened.
- The rig sees the SSD come out and go back in, on real hardware.
- On a live call, the expert clicks the phone's video and the mark sticks to the real part.
- One phone photo of a screwdriver became a textured, life-size 3D model on our own GPU in two to four minutes.
- More than 100 automated tests across the relay, the dashboard and the rig.
- Every design call was made by a person, written down where every teammate's agent could see it.

## What we learned
- AR is mostly about coordinate frames. Units, axes and "where is zero" caused more bugs than any library.
- Working offline has to be designed in from the start. Steps are tracked by id, every tap gets a receipt so
  nothing's counted twice, and there's a clear rule for which guide wins when the expert edits while you're offline.
- Prove which side is wrong before fixing anything. Reading the data in the middle stopped us "fixing" a dashboard
  that was already right.
- Read the licence before the install.
- Measure the hardware yourself. Don't trust the forum.
- With four AI coding agents on one repo, writing code is the easy part. Keeping everyone, people and agents, on
  the same page is the hard part. A shared build log and a "people decide" rule stopped us building four different
  products.

## What's next for Sonic Assist
- **A bulletproof anchor:** ignore any marker that isn't our printed size, then measure alignment on the real
  laptop with a ruler, so we can quote a real accuracy number.
- **Scanning inside our own app:** the phone records photos with their camera positions already measured from the
  marker, and our own GPU trains the scan, so it comes out lined up with no clicking. It's built on a branch, but it
  hasn't run on a real scan yet.
- **Cut-outs:** lift the real screw or cable out of the scan as its own object, so the guide animates the actual
  part.
- **A guide library:** MSPs fix the same models at many sites. Teach a laptop's screw positions once and reuse the
  guide everywhere.
- **Beyond the hotspot:** a secure relay reachable from anywhere, with sign-in, so an engineer can help a site on
  the other side of the country.
- **Testing with real people:** time a first-timer doing the swap over a plain video call, then with Sonic Assist.

# The printed marker

| | |
|---|---|
| Image | `marker.png` (2126 × 2126 px, 300 dpi) |
| Print sheet | `marker-print-A4.pdf`: print at 100% / Actual size, never "Fit to page" |
| Printed size, measured | **180 mm × 180 mm**, outside of the black frame |
| In the contract (`Marker`) | `{ "name": "marker", "width": 0.18, "height": 0.18 }` (metres) |

The width and height are measured on the print with a ruler, not taken from the file: ARKit scales everything by
this size, so a reprint has to be measured again and this table updated if it differs.

Print on matte paper (gloss and lamination glare and hide the detail ARKit tracks) and glue it flat onto card. The
"TOP" mark on the sheet is the upright edge that the contract's +X (right) and +Z (bottom) are read from.

The image is generated: random shapes, strokes and characters over multi-scale noise, with a big triangle top-left
and an oval bottom-right so it has no rotational or mirror symmetry. A checkerboard or any repeating pattern tracks
badly because ARKit can't tell its corners apart.

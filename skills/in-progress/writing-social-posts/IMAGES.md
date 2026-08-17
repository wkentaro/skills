# Post images

The media branch of [`writing-social-posts`](SKILL.md), covering stills and the
audio shim X's uploader needs. Build each still as an HTML file rendered by
headless Chrome, so it is a source-controlled artifact you can re-render after a
copy change.

## Render

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --force-device-scale-factor=2 \
  --window-size=1280,720 --screenshot=out.png "file://$PWD/still.html"
```

1280×720 CSS at 2x gives 2560×1440 — 16:9, which X displays without cropping.
Keep every still in a launch at the same ratio.

## Measure, do not eyeball

Composition problems are invisible at a glance and obvious in numbers. After
every render:

```python
from PIL import Image, ImageChops
im = Image.open("out.png").convert("RGB"); w, h = im.size
bg = Image.new("RGB", im.size, im.getpixel((5, 5)))   # corner sampled as background
box = ImageChops.difference(im, bg).getbbox()
if box is None:
    raise SystemExit("blank render — nothing to measure")
left, top, right, bottom = box
print(f"{w}x{h} ratio {w/h:.3f} | top {top} bottom {h-bottom} "
      f"| left {left} right {w-right}")
```

Aim for near-symmetric gaps. Pipe it into `uv run --with pillow python3 -`.

## Two layout traps

**Centering that silently clips.** `justify-content: center` on a body whose
content is taller than its padding box overflows equally at both ends, so the
measured gaps come out *smaller* than the padding you set. That reading — gaps
below the declared padding — means the content must shrink, not that the
centering is broken.

```css
*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; height: 100vh; padding: 72px 68px;
       display: flex; flex-direction: column; justify-content: center; }
```

Both resets are load-bearing. Without `border-box` the padding adds to the
`100vh`, and the default `body` margin adds 8px more, so the frame overflows
before any content does.

**Code panels sized by the layout instead of the code.** `flex: 1` stretches a
panel to its column, leaving dead space to the right of every line. Size it to
the longest line and spend the reclaimed width on type — legibility on a phone
is the whole point of a still.

```css
.panel { width: calc(30ch + 46px); }   /* longest line is 30 chars; + gutters + border */
```

On the git-hunk before/after still this freed enough room to take the code from
14.5px to 26px inside the same frame.

## Two layouts that carry a launch

- **Teaser table** (shadcn shape) — a white rounded pill holding the install
  command in bold sans at ~46px, then two monospace columns: command, and what it
  does. Around 11 rows. This is the post-one asset for a developer tool. The
  install command is pixels here, so repeat it as text in the post body.
- **Before/after** — two content-width code panels with an arrow between, and the
  single command that did it centered underneath. Label the panels.

Match the terminal theme of any recording in the same thread, so the stills and
the video read as one set. This user's terminal is Catppuccin Mocha.

## Video for X

X's uploader is unreliable with audioless files. Add a silent track:

```bash
ffmpeg -i demo.mp4 -f lavfi -i anullsrc=r=44100:cl=stereo \
  -shortest -c:v copy -c:a aac demo-x.mp4
```

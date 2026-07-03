# Image Assets

Channel artwork generated from the official Mivio logo
(`mivio-apple/.../AppIcon-iOS.appiconset/icon-ios-dark.png`, orange logo on a
`#151515` background). Non-square sizes are produced by downscaling the logo
and padding with the same `#151515` background so the artwork stays seamless.

Required assets and exact dimensions (referenced from `manifest`):

| File                    | Purpose                        | Dimensions  |
| ----------------------- | ------------------------------ | ----------- |
| `mm_icon_focus_hd.png`  | Home screen channel icon (HD)  | 290 x 218   |
| `mm_icon_focus_fhd.png` | Home screen channel icon (FHD) | 336 x 210   |
| `splash_hd.png`         | Launch splash screen (HD)      | 1280 x 720  |
| `splash_fhd.png`        | Launch splash screen (FHD)     | 1920 x 1080 |

Regenerating (macOS, built-in `sips`; work on a COPY of the source logo since
sips edits in place):

```bash
LOGO=path/to/icon-ios-dark.png   # 1024x1024
cp "$LOGO" /tmp/logo.png && sips --resampleHeightWidthMax 218 --padToHeightWidth 218 290 --padColor 151515 /tmp/logo.png --out images/mm_icon_focus_hd.png
cp "$LOGO" /tmp/logo.png && sips --resampleHeightWidthMax 210 --padToHeightWidth 210 336 --padColor 151515 /tmp/logo.png --out images/mm_icon_focus_fhd.png
cp "$LOGO" /tmp/logo.png && sips --resampleHeightWidthMax 300 --padToHeightWidth 720 1280 --padColor 151515 /tmp/logo.png --out images/splash_hd.png
cp "$LOGO" /tmp/logo.png && sips --resampleHeightWidthMax 400 --padToHeightWidth 1080 1920 --padColor 151515 /tmp/logo.png --out images/splash_fhd.png
```

Notes:

- Keep `splash_color` in `manifest` in sync with the background (`#151515`).
- Keep file names in sync with the `manifest` entries if you rename anything.

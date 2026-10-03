#!/usr/bin/env python3
# Generates the settings-bundle icon and the Cydia depiction icon.
# Skeuomorphic iOS 6 look: a rounded card with a balloon + a ticket-stub notch.
from PIL import Image, ImageDraw
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def rounded(draw, box, r, fill):
    draw.rounded_rectangle(box, radius=r, fill=fill)


def gradient(size, top, bottom):
    img = Image.new("RGB", (1, size[1]))
    for y in range(size[1]):
        t = y / max(1, size[1] - 1)
        img.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return img.resize(size)


def make(px: int) -> Image.Image:
    S = px * 4  # supersample
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # background plate: green (Game Center felt) -> warm card
    bg = gradient((S, S), (76, 170, 96), (54, 132, 74)).convert("RGBA")
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=int(S * 0.22), fill=255)
    img.paste(bg, (0, 0), mask)

    # a pass/ticket card, tilted, with a notch
    m = int(S * 0.20)
    card = [m, int(S * 0.26), S - m, int(S * 0.80)]
    rounded(d, card, int(S * 0.05), (250, 250, 248, 255))
    # top colour strip of the pass
    d.rounded_rectangle([card[0], card[1], card[2], card[1] + int(S * 0.12)],
                        radius=int(S * 0.05), fill=(44, 110, 210, 255))
    d.rectangle([card[0], card[1] + int(S * 0.07), card[2], card[1] + int(S * 0.12)],
                fill=(44, 110, 210, 255))
    # ticket notches on the sides
    nr = int(S * 0.035)
    ny = int(S * 0.56)
    d.ellipse([card[0] - nr, ny - nr, card[0] + nr, ny + nr], fill=(54, 132, 74, 255))
    d.ellipse([card[2] - nr, ny - nr, card[2] + nr, ny + nr], fill=(54, 132, 74, 255))
    # text lines on the pass
    lx0, lx1 = card[0] + int(S * 0.06), card[2] - int(S * 0.06)
    for i, yy in enumerate((0.60, 0.66, 0.72)):
        y = int(S * yy)
        d.rounded_rectangle([lx0, y, lx1 - i * int(S * 0.10), y + int(S * 0.018)],
                            radius=int(S * 0.009), fill=(200, 205, 212, 255))

    # Game Center style balloon badge, bottom-right
    bc = (int(S * 0.70), int(S * 0.70))
    br = int(S * 0.17)
    d.ellipse([bc[0] - br, bc[1] - br, bc[0] + br, bc[1] + br], fill=(236, 90, 70, 255))
    d.ellipse([bc[0] - br, bc[1] - br, bc[0] + br, bc[1] + br],
              outline=(255, 255, 255, 230), width=int(S * 0.012))
    hl = int(br * 0.4)
    d.ellipse([bc[0] - hl, bc[1] - br + int(br * 0.18), bc[0] + hl, bc[1] - int(br * 0.1)],
              fill=(255, 150, 135, 180))

    return img.resize((px, px), Image.LANCZOS)


def main():
    prefs = ROOT / "prefs/Resources"
    prefs.mkdir(parents=True, exist_ok=True)
    # settings icon: 29pt @1x/@2x/@3x
    make(29).save(prefs / "icon.png")
    make(58).save(prefs / "icon@2x.png")
    make(87).save(prefs / "icon@3x.png")
    # Cydia depiction icon
    dep = ROOT / "depiction"
    dep.mkdir(parents=True, exist_ok=True)
    make(256).save(dep / "icon.png")
    print("icons written")


if __name__ == "__main__":
    main()

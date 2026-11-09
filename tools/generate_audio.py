#!/usr/bin/env python3
"""Procedural audio generator for ORBIT SHIFT (original synthesis, no external samples).
Writes 16-bit mono 22.05 kHz WAV files into assets/audio/. Re-run to regenerate."""
import os, wave
import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

def t_(dur): return np.arange(int(SR * dur)) / SR
def env(n, a=0.005, d=0.1, s=0.0, r=0.1, sus_level=0.0):
    e = np.zeros(n); an = max(1, int(a * SR)); dn = max(1, int(d * SR)); rn = max(1, int(r * SR))
    e[:an] = np.linspace(0, 1, an)
    dd = np.linspace(1, sus_level, dn)[: max(0, n - an)]
    e[an:an + len(dd)] = dd[: n - an]
    if an + dn < n: e[an + dn:] = sus_level
    rr = min(rn, n); e[n - rr:] *= np.linspace(1, 0, rr)
    return e
def sine(f, dur, phase=0.0):
    t = t_(dur); f = np.broadcast_to(f, t.shape) if np.isscalar(f) else f
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)
def sweep(f0, f1, dur, expo=True):
    t = t_(dur); f = f0 * (f1 / f0) ** (t / dur) if expo else np.linspace(f0, f1, len(t)); return sine(f, dur)
def saw(f, dur):
    t = t_(dur); ph = np.cumsum(np.full_like(t, f)) / SR; return 2 * (ph % 1.0) - 1
def square(f, dur, duty=0.5):
    t = t_(dur); ph = np.cumsum(np.full_like(t, f)) / SR; return np.where((ph % 1.0) < duty, 1.0, -1.0)
def noise(dur): return rng.uniform(-1, 1, int(SR * dur))
def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR); y = np.zeros_like(x); p = 0.0
    for i, v in enumerate(x): p = (1 - a) * v + a * p; y[i] = p
    return y
def bell(f, dur, decay=7.0):
    t = t_(dur); sig = sum(a * np.sin(2 * np.pi * f * m * t) for m, a in ((1, 1.0), (2.01, 0.45), (3.0, 0.2), (4.2, 0.12)))
    return sig * np.exp(-decay * t)
def norm(x, peak=0.85):
    m = np.max(np.abs(x)) or 1.0; return x / m * peak
def write(name, x):
    x = np.clip(x, -1, 1); data = (x * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())
def place(buf, x, at):
    i = int(at * SR); n = min(len(x), len(buf) - i)
    if n > 0: buf[i:i + n] += x[:n]
NOTE = lambda n: 440.0 * 2 ** ((n - 69) / 12)

# ---------------- SFX ----------------
write("sfx_click", norm(sine(1400, 0.05) * env(int(SR * 0.05), 0.002, 0.04, r=0.02), 0.6))
write("sfx_back", norm(sweep(900, 500, 0.08) * env(int(SR * 0.08), 0.002, 0.07, r=0.02), 0.6))
x = sweep(280, 1100, 0.45) * env(int(SR * 0.45), 0.01, 0.4, r=0.1) + 0.3 * sweep(560, 2200, 0.45) * env(int(SR * 0.45), 0.05, 0.35, r=0.1)
write("sfx_start", norm(x, 0.8))
n = noise(0.09); sh = lowpass(n, 2500) * 0.6 + sweep(480, 780, 0.09) * 0.7
write("sfx_shift", norm(sh * env(int(SR * 0.09), 0.003, 0.08, r=0.03), 0.6))
write("sfx_crystal", norm(bell(1318.5, 0.35, 8) + 0.8 * np.concatenate([np.zeros(int(SR * 0.07)), bell(1976, 0.28, 9)]), 0.75))
arp = np.zeros(int(SR * 0.4))
for i, nn in enumerate((72, 76, 79)): place(arp, bell(NOTE(nn), 0.25, 8) * 0.9, i * 0.07)
write("sfx_combo_up", norm(arp, 0.8))
write("sfx_near_miss", norm(sweep(1400, 2800, 0.1) * env(int(SR * 0.1), 0.003, 0.09, r=0.04), 0.65))
hit = lowpass(noise(0.5), 1800) * np.exp(-9 * t_(0.5)) + sweep(150, 38, 0.5) * np.exp(-5 * t_(0.5)) * 1.2
write("sfx_hit", norm(hit, 0.95))
go = np.zeros(int(SR * 1.1))
for i, nn in enumerate((67, 63, 58)): place(go, (saw(NOTE(nn), 0.4) * 0.5 + sine(NOTE(nn - 12), 0.4)) * env(int(SR * 0.4), 0.01, 0.35, r=0.1) * 0.8, i * 0.26)
write("sfx_gameover", norm(lowpass(go, 3000), 0.8))
rec = np.zeros(int(SR * 1.4))
for i, nn in enumerate((72, 76, 79, 84, 88)): place(rec, bell(NOTE(nn), 0.7, 5) * 0.9, i * 0.11)
place(rec, (bell(NOTE(84), 1.0, 3) + bell(NOTE(88), 1.0, 3)) * 0.7, 0.55)
write("sfx_record", norm(rec, 0.85))
unl = np.zeros(int(SR * 0.9))
for i, nn in enumerate((79, 84, 88, 91, 96)): place(unl, bell(NOTE(nn), 0.4, 7) * 0.8, i * 0.06)
write("sfx_unlock", norm(unl, 0.8))
write("sfx_count", norm(sine(880, 0.14) * env(int(SR * 0.14), 0.004, 0.12, r=0.04), 0.7))
write("sfx_go", norm((sine(1320, 0.3) + 0.4 * sine(1980, 0.3)) * env(int(SR * 0.3), 0.004, 0.28, r=0.08), 0.8))
write("sfx_chain_lost", norm(sweep(700, 180, 0.28) * env(int(SR * 0.28), 0.004, 0.26, r=0.06), 0.65))
write("sfx_phase", norm((sweep(200, 600, 0.35) * 0.6 + sweep(400, 1200, 0.35) * 0.3) * env(int(SR * 0.35), 0.03, 0.3, r=0.1), 0.6))

# ---------------- MUSIC ----------------
def loop_fix(buf, loop_len):
    """Fold the reverb/decay tail beyond loop_len back onto the beginning for a seamless loop."""
    main = buf[:loop_len].copy(); tail = buf[loop_len:]
    main[: len(tail)] += tail[: len(main)]
    return main

def kick():
    t = t_(0.3); return np.sin(2 * np.pi * np.cumsum(55 + 140 * np.exp(-t * 30)) / SR) * np.exp(-t * 11)
def hat(open_=False):
    n = noise(0.12 if open_ else 0.04); n = n - lowpass(n, 6000)
    return n * np.exp(-t_(len(n) / SR) * (26 if open_ else 70)) * 0.35
def pluck(f, dur=0.3):
    t = t_(dur); return (square(f, dur, 0.35) * 0.5 + saw(f * 1.005, dur) * 0.5) * np.exp(-t * 9)
def delay(x, time, fb, taps=3):
    out = x.copy()
    for k in range(1, taps + 1):
        d = int(time * SR * k); out[d:] += x[: len(x) - d] * (fb ** k)
    return out

def make_game_music():
    bpm = 124.0; beat = 60 / bpm; bars = 8; length = bars * 4 * beat
    total = int((length + 2.5) * SR); buf = np.zeros(total); loop_len = int(length * SR)
    chords = [(57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62)]   # Am F C G
    arp = np.zeros(total)
    for bar in range(bars):
        root, third, fifth = chords[bar % 4]
        for b in range(4):
            at = (bar * 4 + b) * beat
            place(buf, kick() * 0.9, at)
            place(buf, hat(), at + beat * 0.5)
            if b % 2 == 1: place(buf, hat(True) * 0.7, at + beat * 0.5 + beat * 0.25) if False else None
        for e in range(8):
            at = (bar * 8 + e) * beat / 2
            bf = NOTE(root - 24)
            place(buf, lowpass(saw(bf, beat / 2), 500 + 300 * (e % 2)) * np.exp(-t_(beat / 2) * 3) * 0.55, at)
        for s in range(16):
            at = (bar * 16 + s) * beat / 4
            nn = (root, third, fifth, third + 12)[s % 4] + (12 if s % 8 >= 4 else 24)
            place(arp, pluck(NOTE(nn), 0.22) * (0.28 if s % 2 == 0 else 0.2), at)
        pad_t = t_(4 * beat); padn = sum(np.sin(2 * np.pi * NOTE(n) * pad_t + i) for i, n in enumerate((root, third, fifth)))
        place(buf, padn * 0.05 * np.minimum(1, np.minimum(pad_t / 0.6, (pad_t[-1] - pad_t) / 0.6)), bar * 4 * beat)
    buf += delay(arp, beat * 0.75, 0.45)
    return norm(loop_fix(buf, loop_len), 0.7)

def make_menu_music():
    bpm = 76.0; beat = 60 / bpm; bars = 8; length = bars * 4 * beat
    total = int((length + 4.0) * SR); buf = np.zeros(total); loop_len = int(length * SR)
    chords = [(57, 60, 64, 67), (53, 57, 60, 64), (48, 52, 55, 59), (55, 59, 62, 66)]
    for bar in range(bars):
        c = chords[bar % 4]; pad_t = t_(4 * beat + 1.5)
        for i, n in enumerate(c):
            sig = np.sin(2 * np.pi * NOTE(n) * pad_t) + 0.4 * np.sin(2 * np.pi * NOTE(n) * 2.003 * pad_t)
            a = np.minimum(1, pad_t / 1.2) * np.minimum(1, (pad_t[-1] - pad_t) / 1.4)
            place(buf, sig * a * 0.11, bar * 4 * beat)
        place(buf, sine(NOTE(c[0] - 24), 4 * beat) * 0.35 * np.minimum(1, t_(4 * beat) / 0.3), bar * 4 * beat)
        for k in range(4):
            if (bar + k) % 2 == 0:
                place(buf, bell(NOTE(c[(k * 2) % 4] + 24), 1.6, 3.2) * 0.14, (bar * 4 + k) * beat)
    buf += delay(buf, beat * 1.5, 0.35, 3) * 0.6
    return norm(loop_fix(buf, loop_len), 0.6)

write("music_game", make_game_music())
write("music_menu", make_menu_music())
print("audio written to", os.path.abspath(OUT))

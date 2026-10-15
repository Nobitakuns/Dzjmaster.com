"""Create small original synthesized prototype SFX with the Python standard library."""
import math
import random
import wave
from pathlib import Path

RATE = 22050
DEST = Path(__file__).resolve().parents[1] / "assets" / "audio"
DEST.mkdir(parents=True, exist_ok=True)
random.seed(8)


def save(name, seconds, generator):
    frames = bytearray()
    count = int(seconds * RATE)
    for index in range(count):
        t = index / RATE
        sample = max(-1.0, min(1.0, generator(t, t / seconds)))
        frames += int(sample * 21000).to_bytes(2, "little", signed=True)
    with wave.open(str(DEST / f"{name}.wav"), "wb") as audio:
        audio.setnchannels(1)
        audio.setsampwidth(2)
        audio.setframerate(RATE)
        audio.writeframes(frames)


save("hit", 0.18, lambda t, p: ((random.random() * 2 - 1) * 0.58 + math.sin(2 * math.pi * (260 - 110 * p) * t) * 0.42) * (1 - p) ** 2)
save("block", 0.16, lambda t, p: (math.sin(2 * math.pi * 120 * t) * 0.72 + (random.random() * 2 - 1) * 0.23) * (1 - p) ** 3)
save("skill", 0.44, lambda t, p: (math.sin(2 * math.pi * (400 + 900 * p) * t) * 0.6 + math.sin(2 * math.pi * (130 + 420 * p) * t) * 0.22) * math.sin(math.pi * p) ** 1.1)
save("ultimate", 0.68, lambda t, p: (math.sin(2 * math.pi * (120 + 300 * p) * t) * 0.35 + math.sin(2 * math.pi * 520 * t) * 0.3 + math.sin(2 * math.pi * 780 * t) * 0.15) * math.sin(math.pi * p) ** 0.75)
save("ko", 0.55, lambda t, p: (math.sin(2 * math.pi * (330 - 220 * p) * t) * 0.65 + math.sin(2 * math.pi * (165 - 110 * p) * t) * 0.24) * (1 - p) ** 1.3)

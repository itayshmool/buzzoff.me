"""Generate alert WAV sound files for BuzzOff app."""
import math
import struct
import wave

SAMPLE_RATE = 44100
OUTPUT_DIR = "../app/assets"


def write_wav(filename: str, samples: list[float], sample_rate: int = SAMPLE_RATE):
    """Write float samples (-1.0 to 1.0) as 16-bit mono WAV."""
    path = f"{OUTPUT_DIR}/{filename}"
    with wave.open(path, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            wf.writeframes(struct.pack("<h", int(clamped * 32767)))
    print(f"  {filename}: {len(samples)} samples, {len(samples)/sample_rate:.2f}s")


def sine(freq: float, duration: float, volume: float = 0.8) -> list[float]:
    n = int(SAMPLE_RATE * duration)
    return [volume * math.sin(2 * math.pi * freq * i / SAMPLE_RATE) for i in range(n)]


def square(freq: float, duration: float, volume: float = 0.6) -> list[float]:
    n = int(SAMPLE_RATE * duration)
    return [volume * (1.0 if math.sin(2 * math.pi * freq * i / SAMPLE_RATE) >= 0 else -1.0) for i in range(n)]


def silence(duration: float) -> list[float]:
    return [0.0] * int(SAMPLE_RATE * duration)


def fade_out(samples: list[float], fade_ms: int = 50) -> list[float]:
    fade_n = int(SAMPLE_RATE * fade_ms / 1000)
    result = list(samples)
    for i in range(min(fade_n, len(result))):
        result[-(i + 1)] *= i / fade_n
    return result


def fade_in(samples: list[float], fade_ms: int = 10) -> list[float]:
    fade_n = int(SAMPLE_RATE * fade_ms / 1000)
    result = list(samples)
    for i in range(min(fade_n, len(result))):
        result[i] *= i / fade_n
    return result


def gen_classic_beep():
    """Two-tone square wave: 800Hz then 1000Hz."""
    s = square(800, 0.15) + silence(0.05) + square(1000, 0.15)
    write_wav("alert_classic.wav", fade_out(fade_in(s)))


def gen_radar_ping():
    """Sine sweep 1200->2400Hz with exponential decay."""
    duration = 0.25
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 1200 + 1200 * (t / duration)
        envelope = math.exp(-4 * t / duration)
        samples.append(0.8 * envelope * math.sin(2 * math.pi * freq * t))
    write_wav("alert_radar.wav", samples)


def gen_siren():
    """Alternating sine between 600Hz and 1000Hz, 3 cycles."""
    samples: list[float] = []
    for _ in range(3):
        samples.extend(sine(600, 0.07))
        samples.extend(sine(1000, 0.07))
    write_wav("alert_siren.wav", fade_out(fade_in(samples)))


def gen_coin():
    """Mario coin: B5 (988Hz) then E6 (1319Hz)."""
    s = sine(988, 0.08, 0.7) + sine(1319, 0.2, 0.7)
    write_wav("alert_coin.wav", fade_out(s))


def gen_shell_warning():
    """Descending three-tone: 880, 660, 440 Hz."""
    s = sine(880, 0.1, 0.7) + silence(0.03) + sine(660, 0.1, 0.7) + silence(0.03) + sine(440, 0.15, 0.7)
    write_wav("alert_shell.wav", fade_out(fade_in(s)))


def gen_race_horn():
    """Low horn: 220Hz base + harmonics, 500ms fade out."""
    duration = 0.5
    n = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        envelope = 1.0 - (t / duration) ** 2
        val = (
            0.5 * math.sin(2 * math.pi * 220 * t)
            + 0.25 * math.sin(2 * math.pi * 440 * t)
            + 0.15 * math.sin(2 * math.pi * 660 * t)
            + 0.1 * math.sin(2 * math.pi * 880 * t)
        )
        samples.append(0.7 * envelope * val)
    write_wav("alert_horn.wav", samples)


if __name__ == "__main__":
    print("Generating alert sounds...")
    gen_classic_beep()
    gen_radar_ping()
    gen_siren()
    gen_coin()
    gen_shell_warning()
    gen_race_horn()
    print("Done!")

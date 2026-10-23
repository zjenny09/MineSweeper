using System;
using System.IO;

/// <summary>
/// Leisure forest paper-cut BGM in a Nintendo-like pastoral style,
/// with layered cricket / cicada ambience.
/// </summary>
public static class ForestPapercutBgm
{
    const int Sr = 44100;
    const double Bpm = 88.0;
    const double TwoPi = Math.PI * 2.0;

    static readonly Random Rng = new Random(20260915);

    static int BeatToSample(double beat)
    {
        return (int)(beat * 60.0 / Bpm * Sr);
    }

    static double MidiHz(double midi)
    {
        return 440.0 * Math.Pow(2.0, (midi - 69.0) / 12.0);
    }

    static double Lerp(double a, double b, double t)
    {
        return a + (b - a) * t;
    }

    static double Clamp(double x, double lo, double hi)
    {
        return x < lo ? lo : (x > hi ? hi : x);
    }

    static double Soft(double x)
    {
        return Math.Tanh(x);
    }

    static void Mix(double[] L, double[] R, int i, double s, double pan, double gain)
    {
        if (i < 0 || i >= L.Length) return;
        double pl = Math.Cos((pan + 1.0) * Math.PI * 0.25);
        double pr = Math.Sin((pan + 1.0) * Math.PI * 0.25);
        L[i] += s * pl * gain;
        R[i] += s * pr * gain;
    }

    static double EnvADSR(double t, double dur, double a, double d, double s, double r)
    {
        if (t < 0 || t > dur + r) return 0;
        if (t < a) return t / Math.Max(a, 1e-4);
        if (t < a + d) return Lerp(1.0, s, (t - a) / Math.Max(d, 1e-4));
        if (t < dur) return s;
        double rel = (t - dur) / Math.Max(r, 1e-4);
        return s * (1.0 - Clamp(rel, 0, 1));
    }

    static double OnePoleLp(ref double state, double x, double alpha)
    {
        state += alpha * (x - state);
        return state;
    }

    // --- instruments --------------------------------------------------------

    static void Kalimba(double[] L, double[] R, double beat, double durBeats, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = BeatToSample(durBeats + 0.9);
        double f = MidiHz(midi);
        double g = vel * 0.22;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 3.8) * (1.0 - Math.Exp(-t * 180.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.32 * Math.Sin(ph * 2.003) * Math.Exp(-t * 7.5)
                + 0.11 * Math.Sin(ph * 2.763) * Math.Exp(-t * 11.0)
                + 0.07 * Math.Sin(ph * 4.081) * Math.Exp(-t * 14.0);
            s = OnePoleLp(ref lp, s, 0.35);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void Flute(double[] L, double[] R, double beat, double durBeats, double midi, double vel, double pan)
    {
        // Bright paper whistle: airy and short, not a hummed sine in the voice band.
        if (midi < 74) midi += 12;
        int i0 = BeatToSample(beat);
        double dur = durBeats * 60.0 / Bpm;
        int n = (int)((dur + 0.11) * Sr);
        double f0 = MidiHz(midi);
        double g = vel * 0.12;
        double lp = 0, body = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = EnvADSR(t, dur, 0.02, 0.07, 0.52, 0.09);
            double ph = TwoPi * f0 * t;
            double air = (Rng.NextDouble() * 2.0 - 1.0) * 0.018 * e;
            double s = 0.42 * Math.Sin(ph)
                + 0.38 * Math.Sin(ph * 2.0)
                + 0.16 * Math.Sin(ph * 3.01)
                + 0.07 * Math.Sin(ph * 4.02)
                + air;
            s = OnePoleLp(ref lp, s, 0.28);
            s -= 0.40 * OnePoleLp(ref body, s, 0.07);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void Harp(double[] L, double[] R, double beat, double durBeats, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = BeatToSample(durBeats + 0.55);
        double f = MidiHz(midi);
        double g = vel * 0.13;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double drop = 1.0 + 0.012 * Math.Exp(-t * 40.0);
            double e = Math.Exp(-t * 5.6) * (1.0 - Math.Exp(-t * 220.0));
            double ph = TwoPi * f * drop * t;
            double s = Math.Sin(ph) + 0.22 * Math.Sin(ph * 2.0) * Math.Exp(-t * 8)
                + 0.08 * Math.Sin(ph * 3.01) * Math.Exp(-t * 12);
            s = OnePoleLp(ref lp, s, 0.4);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void Bass(double[] L, double[] R, double beat, double durBeats, double midi, double vel)
    {
        int i0 = BeatToSample(beat);
        double dur = durBeats * 60.0 / Bpm;
        int n = (int)((dur + 0.12) * Sr);
        double f = MidiHz(midi);
        double g = vel * 0.28;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = EnvADSR(t, dur, 0.012, 0.08, 0.7, 0.1);
            double tri = 2.0 * Math.Abs(2.0 * ((f * t) % 1.0) - 1.0) - 1.0;
            double s = 0.72 * Math.Sin(TwoPi * f * t) + 0.28 * tri;
            s = OnePoleLp(ref lp, s, 0.18);
            Mix(L, R, i0 + k, s * e, 0.0, g);
        }
    }

    static void Pad(double[] L, double[] R, double beat, double durBeats, double[] midis, double vel)
    {
        int i0 = BeatToSample(beat);
        double dur = durBeats * 60.0 / Bpm;
        int n = (int)((dur + 0.8) * Sr);
        double g = vel * 0.045;
        for (int m = 0; m < midis.Length; m++)
        {
            double f = MidiHz(midis[m]);
            double pan = (m - (midis.Length - 1) * 0.5) * 0.18;
            for (int d = -1; d <= 1; d++)
            {
                double fd = f * Math.Pow(2.0, d * 0.03 / 12.0);
                for (int k = 0; k < n; k++)
                {
                    double t = k / (double)Sr;
                    double e = EnvADSR(t, dur, 0.45, 0.3, 0.85, 0.7);
                    double s = Math.Sin(TwoPi * fd * t);
                    Mix(L, R, i0 + k, s * e, pan, g);
                }
            }
        }
    }

    static void BellSparkle(double[] L, double[] R, double beat, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = (int)(0.9 * Sr);
        double f = MidiHz(midi);
        double g = vel * 0.09;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 6.5) * (1.0 - Math.Exp(-t * 90));
            double s = Math.Sin(TwoPi * f * t) + 0.4 * Math.Sin(TwoPi * f * 2.01 * t) * Math.Exp(-t * 9);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    // --- forest ambience ----------------------------------------------------

    static void CricketBurst(double[] L, double[] R, double tSec, double pan)
    {
        int pulses = 3 + Rng.Next(6);
        double f0 = 3600 + Rng.NextDouble() * 2200;
        double gap = 0.016 + Rng.NextDouble() * 0.02;
        double pw = 0.0055 + Rng.NextDouble() * 0.007;
        double amp = 0.010 + Rng.NextDouble() * 0.018;
        int i0 = (int)(tSec * Sr);
        for (int p = 0; p < pulses; p++)
        {
            double f = f0 * (1.0 + 0.03 * (Rng.NextDouble() - 0.5));
            int j0 = i0 + (int)(p * gap * Sr);
            int pn = (int)(pw * Sr);
            for (int k = 0; k < pn; k++)
            {
                double t = k / (double)Sr;
                double w = Math.Sin(Math.PI * k / Math.Max(pn - 1, 1));
                double s = Math.Sin(TwoPi * f * t) * w;
                Mix(L, R, j0 + k, s, pan, amp);
            }
        }
    }

    static void CicadaBed(double[] L, double[] R, int n)
    {
        double lp = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / (double)Sr;
            double gate = 0.55 + 0.45 * Math.Sin(TwoPi * t / 11.0);
            double am = 0.5 + 0.5 * Math.Sin(TwoPi * 52.0 * t);
            double f = 5050 + 180 * Math.Sin(TwoPi * 0.17 * t);
            double s = Math.Sin(TwoPi * f * t) * am * gate;
            s = OnePoleLp(ref lp, s, 0.12);
            Mix(L, R, i, s, -0.35, 0.0075);
            Mix(L, R, i, s * 0.7, 0.42, 0.0055);
        }
    }

    static void Leaves(double[] L, double[] R, int n)
    {
        double lpL = 0, lpR = 0, hpL = 0, hpR = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / (double)Sr;
            double wind = 0.35 + 0.65 * (0.5 + 0.5 * Math.Sin(TwoPi * t / 7.5));
            wind *= 0.7 + 0.3 * Math.Sin(TwoPi * t / 3.1);
            double nL = Rng.NextDouble() * 2 - 1;
            double nR = Rng.NextDouble() * 2 - 1;
            nL = OnePoleLp(ref lpL, nL, 0.08);
            nR = OnePoleLp(ref lpR, nR, 0.08);
            hpL = nL - OnePoleLp(ref hpL, nL, 0.02);
            hpR = nR - OnePoleLp(ref hpR, nR, 0.02);
            Mix(L, R, i, hpL * wind, -0.55, 0.028);
            Mix(L, R, i, hpR * wind, 0.55, 0.028);
        }
    }

    static void SprinkleCrickets(double[] L, double[] R, double seconds)
    {
        double t = 0.4;
        while (t < seconds - 0.6)
        {
            CricketBurst(L, R, t, (Rng.NextDouble() * 2.0 - 1.0) * 0.85);
            if (Rng.NextDouble() < 0.35)
                CricketBurst(L, R, t + 0.08 + Rng.NextDouble() * 0.2, (Rng.NextDouble() * 2.0 - 1.0) * 0.85);
            t += 0.35 + Rng.NextDouble() * 1.25;
        }
    }

    // --- arrangement --------------------------------------------------------

    static void ArpBar(double[] L, double[] R, double barBeat, int[] chord, double vel)
    {
        // Nintendo-style 8th-note harp outline: 1 3 5 8 5 3 5 8
        int[] idx = { 0, 1, 2, 3, 2, 1, 2, 3 };
        for (int i = 0; i < 8; i++)
        {
            double v = vel * (i == 0 || i == 4 ? 1.0 : 0.78);
            Harp(L, R, barBeat + i * 0.5, 0.55, chord[idx[i]], v, (i % 2 == 0) ? -0.12 : 0.16);
        }
    }

    static void BassBar(double[] L, double[] R, double barBeat, int root, bool passing)
    {
        Bass(L, R, barBeat, 2.0, root - 12, 0.9);
        Bass(L, R, barBeat + 2.0, passing ? 1.5 : 2.0, root - 5, 0.72);
        if (passing)
            Bass(L, R, barBeat + 3.5, 0.5, root - 7, 0.55);
    }

    static void WriteWav(string path, double[] L, double[] R)
    {
        int n = L.Length;
        double peak = 1e-9;
        for (int i = 0; i < n; i++)
        {
            peak = Math.Max(peak, Math.Abs(L[i]));
            peak = Math.Max(peak, Math.Abs(R[i]));
        }
        double norm = 0.89 / peak;
        using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write))
        using (var bw = new BinaryWriter(fs))
        {
            int dataBytes = n * 4;
            bw.Write(System.Text.Encoding.ASCII.GetBytes("RIFF"));
            bw.Write(36 + dataBytes);
            bw.Write(System.Text.Encoding.ASCII.GetBytes("WAVE"));
            bw.Write(System.Text.Encoding.ASCII.GetBytes("fmt "));
            bw.Write(16);
            bw.Write((short)1);
            bw.Write((short)2);
            bw.Write(Sr);
            bw.Write(Sr * 4);
            bw.Write((short)4);
            bw.Write((short)16);
            bw.Write(System.Text.Encoding.ASCII.GetBytes("data"));
            bw.Write(dataBytes);
            for (int i = 0; i < n; i++)
            {
                short sl = (short)Clamp(Soft(L[i] * norm * 1.05) * 32767.0, -32767, 32767);
                short sr = (short)Clamp(Soft(R[i] * norm * 1.05) * 32767.0, -32767, 32767);
                bw.Write(sl);
                bw.Write(sr);
            }
        }
    }

    static void Reverb(double[] L, double[] R)
    {
        int n = L.Length;
        var l2 = (double[])L.Clone();
        var r2 = (double[])R.Clone();
        int[] taps = { 1301, 1627, 1867, 2309, 2999, 3557 };
        double[] g = { 0.22, 0.18, 0.15, 0.12, 0.09, 0.07 };
        for (int i = 0; i < n; i++)
        {
            double wl = 0, wr = 0;
            for (int t = 0; t < taps.Length; t++)
            {
                int j = i - taps[t];
                if (j >= 0)
                {
                    wl += l2[j] * g[t];
                    wr += r2[j] * g[t];
                }
                int k = i - taps[t] - 211;
                if (k >= 0)
                {
                    wl += r2[k] * g[t] * 0.35;
                    wr += l2[k] * g[t] * 0.35;
                }
            }
            L[i] = l2[i] + wl * 0.38;
            R[i] = r2[i] + wr * 0.38;
        }
    }

    public static void Generate(string path)
    {
        // Intro 2 + A 8 + B 8 + Ending 2 = 20 bars
        const int bars = 20;
        double totalBeats = bars * 4.0;
        double seconds = totalBeats * 60.0 / Bpm + 1.8;
        int n = (int)(seconds * Sr);
        var L = new double[n];
        var R = new double[n];

        Leaves(L, R, n);
        CicadaBed(L, R, n);
        SprinkleCrickets(L, R, seconds);

        // Chord tones: root, 3rd, 5th, octave  (MIDI)
        int[] G  = { 67, 71, 74, 79 };
        int[] Em = { 64, 67, 71, 76 };
        int[] C  = { 60, 64, 67, 72 };
        int[] D  = { 62, 66, 69, 74 };
        int[] Am = { 69, 72, 76, 81 };

        int[][] progA = { G, Em, C, D, G, Em, Am, D };
        int[][] progB = { C, G, Am, Em, C, D, Em, D };
        int[][] progEnd = { G, G };

        // Pads + harp + bass for intro (bars 0-1)
        Pad(L, R, 0, 8, new double[] { 55, 59, 62, 67 }, 0.7);
        ArpBar(L, R, 0, G, 0.55);
        ArpBar(L, R, 4, G, 0.62);
        BassBar(L, R, 0, 67, false);
        BassBar(L, R, 4, 67, false);
        BellSparkle(L, R, 1.0, 91, 0.5, 0.4);
        BellSparkle(L, R, 5.5, 86, 0.4, -0.35);

        Action<double, int[][], double> arrange = (startBeat, prog, padVel) =>
        {
            for (int b = 0; b < prog.Length; b++)
            {
                double beat = startBeat + b * 4.0;
                int[] ch = prog[b];
                Pad(L, R, beat, 4.0, new double[] { ch[0] - 12, ch[1] - 12, ch[2] - 12, ch[0] }, padVel);
                ArpBar(L, R, beat, ch, 0.7);
                BassBar(L, R, beat, ch[0], b % 4 == 3);
            }
        };

        arrange(8, progA, 0.85);
        arrange(40, progB, 0.48);
        arrange(72, progEnd, 0.55);

        // ---- Melody A: music-box / kalimba, Nintendo pastoral ----
        // bar 2 G
        Kalimba(L, R,  8.00, 0.5, 74, 0.72, 0.18);
        Kalimba(L, R,  8.50, 0.5, 76, 0.68, 0.16);
        Kalimba(L, R,  9.00, 1.0, 79, 0.88, 0.12);
        Kalimba(L, R, 10.00, 0.5, 76, 0.64, 0.14);
        Kalimba(L, R, 10.50, 0.5, 74, 0.62, 0.16);
        Kalimba(L, R, 11.00, 1.0, 71, 0.78, 0.10);
        // bar 3 Em
        Kalimba(L, R, 12.00, 0.5, 69, 0.66, 0.18);
        Kalimba(L, R, 12.50, 0.5, 71, 0.66, 0.16);
        Kalimba(L, R, 13.00, 1.0, 76, 0.82, 0.12);
        Kalimba(L, R, 14.00, 0.5, 74, 0.62, 0.14);
        Kalimba(L, R, 14.50, 0.5, 71, 0.62, 0.16);
        Kalimba(L, R, 15.00, 1.0, 67, 0.76, 0.08);
        // bar 4 C
        Kalimba(L, R, 16.00, 0.5, 67, 0.62, 0.18);
        Kalimba(L, R, 16.50, 0.5, 69, 0.64, 0.16);
        Kalimba(L, R, 17.00, 1.0, 72, 0.82, 0.12);
        Kalimba(L, R, 18.00, 0.75, 76, 0.78, 0.10);
        Kalimba(L, R, 18.75, 0.25, 74, 0.58, 0.14);
        Kalimba(L, R, 19.00, 0.5, 72, 0.64, 0.16);
        Kalimba(L, R, 19.50, 0.5, 71, 0.62, 0.18);
        // bar 5 D
        Kalimba(L, R, 20.00, 0.5, 69, 0.68, 0.16);
        Kalimba(L, R, 20.50, 0.5, 66, 0.60, 0.20);
        Kalimba(L, R, 21.00, 0.5, 69, 0.66, 0.16);
        Kalimba(L, R, 21.50, 1.0, 74, 0.86, 0.10);
        Kalimba(L, R, 22.50, 0.5, 72, 0.62, 0.14);
        Kalimba(L, R, 23.00, 0.5, 71, 0.70, 0.12);
        Kalimba(L, R, 23.50, 0.5, 69, 0.58, 0.16);
        // bar 6 G  — lift
        Kalimba(L, R, 24.00, 0.5, 74, 0.74, 0.14);
        Kalimba(L, R, 24.50, 0.5, 76, 0.74, 0.12);
        Kalimba(L, R, 25.00, 0.75, 79, 0.90, 0.08);
        Kalimba(L, R, 25.75, 0.25, 81, 0.72, 0.18);
        Kalimba(L, R, 26.00, 1.0, 83, 0.86, 0.06);
        Kalimba(L, R, 27.00, 0.5, 81, 0.70, 0.12);
        Kalimba(L, R, 27.50, 0.5, 79, 0.72, 0.10);
        // bar 7 Em
        Kalimba(L, R, 28.00, 0.5, 76, 0.72, 0.14);
        Kalimba(L, R, 28.50, 0.5, 74, 0.66, 0.16);
        Kalimba(L, R, 29.00, 1.0, 71, 0.78, 0.10);
        Kalimba(L, R, 30.00, 0.5, 67, 0.62, 0.16);
        Kalimba(L, R, 30.50, 0.5, 69, 0.64, 0.14);
        Kalimba(L, R, 31.00, 1.0, 71, 0.70, 0.12);
        // bar 8 Am
        Kalimba(L, R, 32.00, 0.5, 72, 0.72, 0.14);
        Kalimba(L, R, 32.50, 0.5, 76, 0.74, 0.12);
        Kalimba(L, R, 33.00, 1.0, 79, 0.86, 0.08);
        Kalimba(L, R, 34.00, 0.5, 76, 0.68, 0.14);
        Kalimba(L, R, 34.50, 0.5, 72, 0.62, 0.16);
        Kalimba(L, R, 35.00, 1.0, 69, 0.70, 0.10);
        // bar 9 D
        Kalimba(L, R, 36.00, 0.5, 74, 0.74, 0.12);
        Kalimba(L, R, 36.50, 0.5, 76, 0.68, 0.14);
        Kalimba(L, R, 37.00, 1.0, 78, 0.86, 0.08);
        Kalimba(L, R, 38.00, 0.5, 76, 0.66, 0.14);
        Kalimba(L, R, 38.50, 0.5, 74, 0.72, 0.12);
        Kalimba(L, R, 39.00, 0.5, 71, 0.62, 0.16);
        Kalimba(L, R, 39.50, 0.5, 69, 0.58, 0.18);

        // echo sparkles of A theme
        BellSparkle(L, R, 9.05, 91, 0.35, 0.55);
        BellSparkle(L, R, 25.1, 95, 0.32, -0.45);
        BellSparkle(L, R, 33.1, 91, 0.30, 0.50);

        // ---- Melody B: bright whistle, no low hummed long tones ----
        Flute(L, R, 40.00, 1.0, 76, 0.82, -0.22);
        Flute(L, R, 41.00, 1.0, 79, 0.84, -0.20);
        Flute(L, R, 42.00, 1.5, 84, 0.90, -0.16);
        Flute(L, R, 43.50, 0.5, 83, 0.70, -0.18);
        Flute(L, R, 44.00, 1.0, 81, 0.80, -0.20);
        Flute(L, R, 45.00, 0.5, 79, 0.70, -0.22);
        Flute(L, R, 45.50, 0.5, 76, 0.68, -0.20);
        Flute(L, R, 46.00, 1.0, 81, 0.74, -0.16);
        Flute(L, R, 47.00, 1.0, 79, 0.70, -0.18);

        Flute(L, R, 48.00, 0.5, 76, 0.72, -0.22);
        Flute(L, R, 48.50, 0.5, 74, 0.72, -0.20);
        Flute(L, R, 49.00, 1.0, 76, 0.82, -0.18);
        Flute(L, R, 50.00, 1.0, 79, 0.84, -0.16);
        Flute(L, R, 51.00, 1.0, 76, 0.76, -0.20);
        Flute(L, R, 52.00, 1.0, 83, 0.78, -0.18);
        Flute(L, R, 53.00, 1.0, 79, 0.80, -0.16);
        Flute(L, R, 54.00, 1.0, 81, 0.74, -0.16);
        Flute(L, R, 55.00, 1.0, 76, 0.70, -0.16);

        Flute(L, R, 56.00, 0.5, 74, 0.74, -0.20);
        Flute(L, R, 56.50, 0.5, 76, 0.76, -0.18);
        Flute(L, R, 57.00, 1.0, 79, 0.86, -0.16);
        Flute(L, R, 58.00, 1.0, 84, 0.88, -0.12);
        Flute(L, R, 59.00, 0.5, 83, 0.72, -0.18);
        Flute(L, R, 59.50, 0.5, 81, 0.70, -0.20);
        Flute(L, R, 60.00, 0.5, 79, 0.74, -0.18);
        Flute(L, R, 60.50, 0.5, 78, 0.72, -0.16);
        Flute(L, R, 61.00, 1.0, 81, 0.80, -0.16);
        Flute(L, R, 62.00, 0.5, 74, 0.74, -0.18);
        Flute(L, R, 62.50, 0.5, 76, 0.74, -0.16);
        Flute(L, R, 63.00, 1.0, 79, 0.78, -0.14);

        Flute(L, R, 64.00, 1.0, 84, 0.80, -0.16);
        Flute(L, R, 65.00, 0.5, 83, 0.70, -0.18);
        Flute(L, R, 65.50, 0.5, 79, 0.68, -0.20);
        Flute(L, R, 66.00, 0.5, 76, 0.72, -0.18);
        Flute(L, R, 66.50, 0.5, 79, 0.74, -0.16);
        Flute(L, R, 67.00, 1.0, 81, 0.78, -0.14);
        Flute(L, R, 68.00, 0.5, 81, 0.74, -0.16);
        Flute(L, R, 68.50, 0.5, 83, 0.76, -0.14);
        Flute(L, R, 69.00, 1.0, 86, 0.82, -0.12);
        Flute(L, R, 70.00, 1.0, 83, 0.80, -0.14);
        Flute(L, R, 71.00, 0.5, 79, 0.70, -0.16);
        Flute(L, R, 71.50, 0.5, 76, 0.72, -0.14);

        // kalimba answering in B
        Kalimba(L, R, 42.05, 0.4, 88, 0.35, 0.45);
        Kalimba(L, R, 50.05, 0.4, 91, 0.32, 0.50);
        Kalimba(L, R, 58.05, 0.5, 96, 0.30, 0.42);

        // ---- Ending: settle home on G, music box fragment ----
        Kalimba(L, R, 72.00, 0.5, 74, 0.70, 0.12);
        Kalimba(L, R, 72.50, 0.5, 76, 0.68, 0.10);
        Kalimba(L, R, 73.00, 1.0, 79, 0.84, 0.08);
        Kalimba(L, R, 74.00, 1.0, 71, 0.70, 0.10);
        Kalimba(L, R, 75.00, 1.0, 67, 0.78, 0.06);
        Flute(L, R, 76.00, 0.5, 83, 0.50, -0.14);
        Flute(L, R, 76.50, 0.5, 86, 0.48, -0.12);
        Flute(L, R, 77.00, 1.0, 79, 0.46, -0.10);
        Kalimba(L, R, 76.00, 2.5, 67, 0.62, 0.08);
        BellSparkle(L, R, 73.1, 91, 0.40, 0.35);
        BellSparkle(L, R, 77.0, 86, 0.28, -0.30);

        Reverb(L, R);

        // fade in / out so it can sit under a game scene
        int fadeIn = (int)(0.9 * Sr);
        int fadeOut = (int)(2.4 * Sr);
        for (int i = 0; i < fadeIn && i < n; i++)
        {
            double a = i / (double)fadeIn;
            a = a * a * (3 - 2 * a);
            L[i] *= a; R[i] *= a;
        }
        for (int i = 0; i < fadeOut; i++)
        {
            int j = n - 1 - i;
            if (j < 0) break;
            double a = i / (double)fadeOut;
            a = 1.0 - a * a * (3 - 2 * a);
            L[j] *= a; R[j] *= a;
        }

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
        Console.WriteLine("Duration ~{0:0.0}s  BPM {1}", seconds, Bpm);
    }

    static void Main()
    {
        string dir = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location)
                     ?? Directory.GetCurrentDirectory();
        Generate(Path.Combine(dir, "forest_papercut_bgm.wav"));
    }
}

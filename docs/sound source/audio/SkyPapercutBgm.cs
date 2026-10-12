using System;
using System.IO;

/// <summary>
/// Casual sky paper-cut BGM, Nintendo pastoral style, with wind and birds.
/// Circular buffer so the WAV loops seamlessly.
/// </summary>
public static class SkyPapercutBgm
{
    const int Sr = 44100;
    const double Bpm = 92.0;
    const double TwoPi = Math.PI * 2.0;
    const double LoopBeats = 72.0;

    static readonly Random Rng = new Random(20260915);

    static int BeatToSample(double beat)
    {
        return (int)Math.Round(beat * 60.0 / Bpm * Sr);
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

    static int Wrap(int i, int n)
    {
        i %= n;
        if (i < 0) i += n;
        return i;
    }

    static void Mix(double[] L, double[] R, int i, double s, double pan, double gain)
    {
        int n = L.Length;
        i = Wrap(i, n);
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

    static void Kalimba(double[] L, double[] R, double beat, double durBeats, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = BeatToSample(durBeats + 1.0);
        double f = MidiHz(midi);
        double g = vel * 0.20;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 3.2) * (1.0 - Math.Exp(-t * 170.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.30 * Math.Sin(ph * 2.004) * Math.Exp(-t * 6.8)
                + 0.11 * Math.Sin(ph * 2.81) * Math.Exp(-t * 11.0)
                + 0.06 * Math.Sin(ph * 4.12) * Math.Exp(-t * 13.0);
            s = OnePoleLp(ref lp, s, 0.30);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void Flute(double[] L, double[] R, double beat, double durBeats, double midi, double vel, double pan)
    {
        if (midi < 74) midi += 12;
        int i0 = BeatToSample(beat);
        double dur = durBeats * 60.0 / Bpm;
        int n = (int)((dur + 0.11) * Sr);
        double f0 = MidiHz(midi);
        double g = vel * 0.115;
        double lp = 0, body = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = EnvADSR(t, dur, 0.02, 0.07, 0.50, 0.09);
            double ph = TwoPi * f0 * t;
            double air = (Rng.NextDouble() * 2.0 - 1.0) * 0.02 * e;
            double s = 0.40 * Math.Sin(ph)
                + 0.40 * Math.Sin(ph * 2.0)
                + 0.16 * Math.Sin(ph * 3.01)
                + 0.08 * Math.Sin(ph * 4.02)
                + air;
            s = OnePoleLp(ref lp, s, 0.30);
            s -= 0.42 * OnePoleLp(ref body, s, 0.07);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void Harp(double[] L, double[] R, double beat, double durBeats, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = BeatToSample(durBeats + 0.6);
        double f = MidiHz(midi);
        double g = vel * 0.12;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double drop = 1.0 + 0.01 * Math.Exp(-t * 36.0);
            double e = Math.Exp(-t * 5.0) * (1.0 - Math.Exp(-t * 200.0));
            double ph = TwoPi * f * drop * t;
            double s = Math.Sin(ph) + 0.20 * Math.Sin(ph * 2.0) * Math.Exp(-t * 8)
                + 0.07 * Math.Sin(ph * 3.02) * Math.Exp(-t * 12);
            s = OnePoleLp(ref lp, s, 0.38);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void Bass(double[] L, double[] R, double beat, double durBeats, double midi, double vel)
    {
        int i0 = BeatToSample(beat);
        double dur = durBeats * 60.0 / Bpm;
        int n = (int)((dur + 0.14) * Sr);
        double f = MidiHz(midi);
        double g = vel * 0.22;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = EnvADSR(t, dur, 0.016, 0.09, 0.64, 0.12);
            double tri = 2.0 * Math.Abs(2.0 * ((f * t) % 1.0) - 1.0) - 1.0;
            double s = 0.78 * Math.Sin(TwoPi * f * t) + 0.22 * tri;
            s = OnePoleLp(ref lp, s, 0.15);
            Mix(L, R, i0 + k, s * e, 0.0, g);
        }
    }

    static void Pad(double[] L, double[] R, double beat, double durBeats, double[] midis, double vel)
    {
        int i0 = BeatToSample(beat);
        double dur = durBeats * 60.0 / Bpm;
        int n = (int)((dur + 0.85) * Sr);
        double g = vel * 0.038;
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
                    double e = EnvADSR(t, dur, 0.55, 0.32, 0.80, 0.8);
                    Mix(L, R, i0 + k, Math.Sin(TwoPi * fd * t) * e, pan, g);
                }
            }
        }
    }

    static void BellSparkle(double[] L, double[] R, double beat, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = (int)(1.1 * Sr);
        double f = MidiHz(midi);
        double g = vel * 0.08;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 5.4) * (1.0 - Math.Exp(-t * 80));
            double s = Math.Sin(TwoPi * f * t) + 0.48 * Math.Sin(TwoPi * f * 2.013 * t) * Math.Exp(-t * 8);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void WindBed(double[] L, double[] R)
    {
        int n = L.Length;
        double lpL = 0, lpR = 0, hpL = 0, hpR = 0, airL = 0, airR = 0;
        for (int i = 0; i < n; i++)
        {
            double ph = i / (double)n;
            double swell = 0.40 + 0.60 * (0.5 + 0.5 * Math.Sin(TwoPi * 5.0 * ph));
            double gust = 0.35 + 0.65 * (0.5 + 0.5 * Math.Sin(TwoPi * 8.0 * ph + 1.1));
            double panW = 0.62 * Math.Sin(TwoPi * 3.0 * ph);

            double nL = Rng.NextDouble() * 2 - 1;
            double nR = Rng.NextDouble() * 2 - 1;
            nL = OnePoleLp(ref lpL, nL, 0.055);
            nR = OnePoleLp(ref lpR, nR, 0.055);
            double airyL = nL - OnePoleLp(ref hpL, nL, 0.012);
            double airyR = nR - OnePoleLp(ref hpR, nR, 0.012);
            airL = OnePoleLp(ref airL, nL, 0.03);
            airR = OnePoleLp(ref airR, nR, 0.03);

            Mix(L, R, i, airL * swell, -0.35 + panW, 0.048);
            Mix(L, R, i, airR * gust, 0.38 + panW * 0.5, 0.044);
            Mix(L, R, i, airyL * gust, -0.72, 0.026);
            Mix(L, R, i, airyR * swell, 0.74, 0.024);
        }
    }

    static void Whoosh(double[] L, double[] R, double tSec, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((0.9 + Rng.NextDouble() * 0.7) * Sr);
        double lp = 0, hp = 0;
        for (int k = 0; k < n; k++)
        {
            double u = k / (double)Math.Max(n - 1, 1);
            double e = Math.Sin(Math.PI * u);
            double ns = Rng.NextDouble() * 2 - 1;
            ns = OnePoleLp(ref lp, ns, 0.04 + 0.12 * u);
            double air = ns - OnePoleLp(ref hp, ns, 0.02);
            Mix(L, R, i0 + k, (ns * 0.55 + air * 0.45) * e, pan, amp);
        }
    }

    static void BirdTweet(double[] L, double[] R, double tSec, double pan)
    {
        int hops = 2 + Rng.Next(3);
        double f = 2100 + Rng.NextDouble() * 1800;
        double amp = 0.016 + Rng.NextDouble() * 0.014;
        double t0 = tSec;
        for (int h = 0; h < hops; h++)
        {
            int n = (int)((0.035 + Rng.NextDouble() * 0.045) * Sr);
            int i0 = (int)Math.Round(t0 * Sr);
            double f1 = f * (0.92 + Rng.NextDouble() * 0.22);
            for (int k = 0; k < n; k++)
            {
                double u = k / (double)Math.Max(n - 1, 1);
                double fq = Lerp(f, f1, u);
                double e = Math.Sin(Math.PI * u);
                double s = Math.Sin(TwoPi * fq * (k / (double)Sr))
                    + 0.18 * Math.Sin(TwoPi * fq * 2.0 * (k / (double)Sr)) * e;
                Mix(L, R, i0 + k, s * e, pan, amp);
            }
            f = f1 * (0.96 + Rng.NextDouble() * 0.12);
            t0 += 0.045 + Rng.NextDouble() * 0.05;
        }
    }

    static void SprinkleSky(double[] L, double[] R, double loopSec)
    {
        double t = 1.1;
        while (t < loopSec)
        {
            Whoosh(L, R, t, (Rng.NextDouble() * 2 - 1) * 0.75, 0.030 + Rng.NextDouble() * 0.018);
            t += 3.2 + Rng.NextDouble() * 3.8;
        }
        t = 0.8;
        while (t < loopSec)
        {
            BirdTweet(L, R, t, (Rng.NextDouble() * 2 - 1) * 0.85);
            if (Rng.NextDouble() < 0.28)
                BirdTweet(L, R, t + 0.18 + Rng.NextDouble() * 0.25, (Rng.NextDouble() * 2 - 1) * 0.85);
            t += 1.6 + Rng.NextDouble() * 2.8;
        }
    }

    static void ArpBar(double[] L, double[] R, double barBeat, int[] chord, double vel)
    {
        int[] idx = { 0, 1, 2, 3, 2, 1, 2, 3 };
        for (int i = 0; i < 8; i++)
        {
            double v = vel * (i == 0 || i == 3 ? 1.0 : 0.76);
            Harp(L, R, barBeat + i * 0.5, 0.55, chord[idx[i]], v, (i % 2 == 0) ? -0.16 : 0.20);
        }
    }

    static void BassBar(double[] L, double[] R, double barBeat, int root, bool passing)
    {
        Bass(L, R, barBeat, 2.0, root - 12, 0.82);
        Bass(L, R, barBeat + 2.0, passing ? 1.5 : 2.0, root - 5, 0.64);
        if (passing)
            Bass(L, R, barBeat + 3.5, 0.5, root - 7, 0.48);
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
                short sl = (short)Clamp(Soft(L[i] * norm * 1.04) * 32767.0, -32767, 32767);
                short sr = (short)Clamp(Soft(R[i] * norm * 1.04) * 32767.0, -32767, 32767);
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
        int[] taps = { 1483, 1783, 2089, 2557, 3253, 3821 };
        double[] g = { 0.25, 0.20, 0.16, 0.13, 0.10, 0.08 };
        for (int i = 0; i < n; i++)
        {
            double wl = 0, wr = 0;
            for (int t = 0; t < taps.Length; t++)
            {
                int j = Wrap(i - taps[t], n);
                int k = Wrap(i - taps[t] - 241, n);
                wl += l2[j] * g[t] + r2[k] * g[t] * 0.40;
                wr += r2[j] * g[t] + l2[k] * g[t] * 0.40;
            }
            L[i] = l2[i] + wl * 0.46;
            R[i] = r2[i] + wr * 0.46;
        }
    }

    public static void Generate(string path)
    {
        int n = BeatToSample(LoopBeats);
        double loopSec = n / (double)Sr;
        var L = new double[n];
        var R = new double[n];

        WindBed(L, R);
        SprinkleSky(L, R, loopSec);

        int[] C  = { 60, 64, 67, 72 };
        int[] Am = { 57, 60, 64, 69 };
        int[] F  = { 65, 69, 72, 77 };
        int[] G  = { 67, 71, 74, 79 };
        int[] Em = { 64, 67, 71, 76 };
        int[] Dm = { 62, 65, 69, 74 };

        int[][] progA = { C, Am, F, G, C, Em, F, G };
        int[][] progB = { F, C, Am, G, F, Dm, Em, G };

        Pad(L, R, 0, 8, new double[] { 48, 52, 55, 60 }, 0.72);
        ArpBar(L, R, 0, C, 0.56);
        ArpBar(L, R, 4, C, 0.62);
        BassBar(L, R, 0, 60, false);
        BassBar(L, R, 4, 60, false);
        BellSparkle(L, R, 1.0, 84, 0.50, 0.40);
        BellSparkle(L, R, 5.5, 88, 0.42, -0.34);

        Action<double, int[][], double> arrange = (startBeat, prog, padVel) =>
        {
            for (int b = 0; b < prog.Length; b++)
            {
                double beat = startBeat + b * 4.0;
                int[] ch = prog[b];
                Pad(L, R, beat, 4.0, new double[] { ch[0] - 12, ch[1] - 12, ch[2] - 12, ch[0] }, padVel);
                ArpBar(L, R, beat, ch, 0.70);
                BassBar(L, R, beat, ch[0], b % 4 == 3);
            }
        };

        arrange(8, progA, 0.82);
        arrange(40, progB, 0.46);

        // A: music-box, floating C major
        Kalimba(L, R,  8.00, 0.5, 76, 0.70, 0.16);
        Kalimba(L, R,  8.50, 0.5, 79, 0.72, 0.14);
        Kalimba(L, R,  9.00, 1.0, 84, 0.88, 0.08);
        Kalimba(L, R, 10.00, 0.5, 81, 0.64, 0.14);
        Kalimba(L, R, 10.50, 0.5, 79, 0.62, 0.16);
        Kalimba(L, R, 11.00, 1.0, 76, 0.76, 0.10);

        Kalimba(L, R, 12.00, 0.5, 74, 0.66, 0.18);
        Kalimba(L, R, 12.50, 0.5, 76, 0.66, 0.16);
        Kalimba(L, R, 13.00, 1.0, 81, 0.82, 0.12);
        Kalimba(L, R, 14.00, 0.5, 79, 0.62, 0.14);
        Kalimba(L, R, 14.50, 0.5, 76, 0.62, 0.16);
        Kalimba(L, R, 15.00, 1.0, 72, 0.74, 0.08);

        Kalimba(L, R, 16.00, 0.5, 72, 0.64, 0.16);
        Kalimba(L, R, 16.50, 0.5, 77, 0.66, 0.14);
        Kalimba(L, R, 17.00, 1.0, 81, 0.82, 0.10);
        Kalimba(L, R, 18.00, 0.75, 84, 0.80, 0.08);
        Kalimba(L, R, 18.75, 0.25, 83, 0.58, 0.14);
        Kalimba(L, R, 19.00, 0.5, 81, 0.64, 0.16);
        Kalimba(L, R, 19.50, 0.5, 79, 0.62, 0.18);

        Kalimba(L, R, 20.00, 0.5, 79, 0.70, 0.14);
        Kalimba(L, R, 20.50, 0.5, 76, 0.62, 0.18);
        Kalimba(L, R, 21.00, 0.5, 79, 0.68, 0.14);
        Kalimba(L, R, 21.50, 1.0, 83, 0.86, 0.10);
        Kalimba(L, R, 22.50, 0.5, 81, 0.64, 0.14);
        Kalimba(L, R, 23.00, 0.5, 79, 0.70, 0.12);
        Kalimba(L, R, 23.50, 0.5, 76, 0.58, 0.16);

        Kalimba(L, R, 24.00, 0.5, 76, 0.76, 0.12);
        Kalimba(L, R, 24.50, 0.5, 79, 0.74, 0.12);
        Kalimba(L, R, 25.00, 0.75, 84, 0.90, 0.08);
        Kalimba(L, R, 25.75, 0.25, 86, 0.72, 0.18);
        Kalimba(L, R, 26.00, 1.0, 88, 0.86, 0.04);
        Kalimba(L, R, 27.00, 0.5, 84, 0.70, 0.12);
        Kalimba(L, R, 27.50, 0.5, 81, 0.72, 0.10);

        Kalimba(L, R, 28.00, 0.5, 79, 0.72, 0.14);
        Kalimba(L, R, 28.50, 0.5, 76, 0.66, 0.16);
        Kalimba(L, R, 29.00, 1.0, 71, 0.76, 0.10);
        Kalimba(L, R, 30.00, 0.5, 74, 0.64, 0.14);
        Kalimba(L, R, 30.50, 0.5, 76, 0.66, 0.12);
        Kalimba(L, R, 31.00, 1.0, 79, 0.72, 0.10);

        Kalimba(L, R, 32.00, 0.5, 77, 0.70, 0.14);
        Kalimba(L, R, 32.50, 0.5, 81, 0.72, 0.12);
        Kalimba(L, R, 33.00, 1.0, 84, 0.84, 0.08);
        Kalimba(L, R, 34.00, 0.5, 81, 0.70, 0.14);
        Kalimba(L, R, 34.50, 0.5, 77, 0.64, 0.16);
        Kalimba(L, R, 35.00, 1.0, 72, 0.70, 0.10);

        Kalimba(L, R, 36.00, 0.5, 79, 0.74, 0.12);
        Kalimba(L, R, 36.50, 0.5, 81, 0.70, 0.14);
        Kalimba(L, R, 37.00, 1.0, 83, 0.86, 0.08);
        Kalimba(L, R, 38.00, 0.5, 81, 0.66, 0.14);
        Kalimba(L, R, 38.50, 0.5, 79, 0.72, 0.12);
        Kalimba(L, R, 39.00, 0.5, 76, 0.64, 0.16);
        Kalimba(L, R, 39.50, 0.5, 74, 0.60, 0.18);

        BellSparkle(L, R, 9.05, 96, 0.34, 0.52);
        BellSparkle(L, R, 25.1, 100, 0.30, -0.42);
        BellSparkle(L, R, 33.1, 96, 0.28, 0.48);

        // B: bright whistle, high and short — no hummed drones
        Flute(L, R, 40.00, 1.0, 77, 0.80, -0.20);
        Flute(L, R, 41.00, 1.0, 81, 0.82, -0.18);
        Flute(L, R, 42.00, 1.5, 88, 0.88, -0.12);
        Flute(L, R, 43.50, 0.5, 86, 0.68, -0.16);
        Flute(L, R, 44.00, 1.0, 84, 0.80, -0.18);
        Flute(L, R, 45.00, 0.5, 81, 0.68, -0.20);
        Flute(L, R, 45.50, 0.5, 77, 0.66, -0.18);
        Flute(L, R, 46.00, 1.0, 84, 0.72, -0.16);
        Flute(L, R, 47.00, 1.0, 81, 0.68, -0.16);

        Flute(L, R, 48.00, 0.5, 76, 0.72, -0.20);
        Flute(L, R, 48.50, 0.5, 79, 0.72, -0.18);
        Flute(L, R, 49.00, 1.0, 84, 0.82, -0.16);
        Flute(L, R, 50.00, 1.0, 81, 0.80, -0.14);
        Flute(L, R, 51.00, 1.0, 76, 0.74, -0.18);
        Flute(L, R, 52.00, 1.0, 79, 0.76, -0.16);
        Flute(L, R, 53.00, 1.0, 83, 0.80, -0.14);
        Flute(L, R, 54.00, 1.0, 86, 0.74, -0.14);
        Flute(L, R, 55.00, 1.0, 81, 0.70, -0.16);

        Flute(L, R, 56.00, 0.5, 77, 0.74, -0.18);
        Flute(L, R, 56.50, 0.5, 81, 0.76, -0.16);
        Flute(L, R, 57.00, 1.0, 84, 0.84, -0.14);
        Flute(L, R, 58.00, 1.0, 88, 0.86, -0.10);
        Flute(L, R, 59.00, 0.5, 86, 0.70, -0.16);
        Flute(L, R, 59.50, 0.5, 84, 0.68, -0.18);
        Flute(L, R, 60.00, 0.5, 81, 0.72, -0.16);
        Flute(L, R, 60.50, 0.5, 79, 0.70, -0.16);
        Flute(L, R, 61.00, 1.0, 84, 0.78, -0.14);
        Flute(L, R, 62.00, 0.5, 79, 0.72, -0.16);
        Flute(L, R, 62.50, 0.5, 81, 0.72, -0.14);
        Flute(L, R, 63.00, 1.0, 83, 0.76, -0.12);

        Flute(L, R, 64.00, 1.0, 88, 0.80, -0.14);
        Flute(L, R, 65.00, 0.5, 86, 0.70, -0.16);
        Flute(L, R, 65.50, 0.5, 84, 0.68, -0.18);
        Flute(L, R, 66.00, 0.5, 79, 0.70, -0.16);
        Flute(L, R, 66.50, 0.5, 81, 0.72, -0.14);
        Flute(L, R, 67.00, 1.0, 84, 0.76, -0.12);
        Flute(L, R, 68.00, 0.5, 83, 0.74, -0.14);
        Flute(L, R, 68.50, 0.5, 86, 0.76, -0.12);
        Flute(L, R, 69.00, 1.0, 88, 0.82, -0.10);
        Flute(L, R, 70.00, 1.0, 83, 0.78, -0.12);
        Flute(L, R, 71.00, 0.5, 81, 0.68, -0.14);
        Flute(L, R, 71.50, 0.5, 79, 0.70, -0.14);

        Kalimba(L, R, 42.05, 0.4, 96, 0.32, 0.46);
        Kalimba(L, R, 50.05, 0.4, 100, 0.28, 0.50);
        Kalimba(L, R, 58.05, 0.5, 103, 0.26, 0.40);

        Reverb(L, R);

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
        Console.WriteLine("Duration {0:0.00}s  BPM {1}  seamless loop", loopSec, Bpm);
    }
}

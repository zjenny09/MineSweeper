using System;
using System.IO;

/// <summary>
/// Casual ocean paper-cut BGM, Nintendo pastoral style, with water bed.
/// Rendered into a circular buffer so the WAV loops seamlessly.
/// </summary>
public static class OceanPapercutBgm
{
    const int Sr = 44100;
    const double Bpm = 84.0;
    const double TwoPi = Math.PI * 2.0;
    const double LoopBeats = 72.0; // 18 bars: 2 intro + 8 A + 8 B

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
        double g = vel * 0.21;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 3.4) * (1.0 - Math.Exp(-t * 160.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.28 * Math.Sin(ph * 2.004) * Math.Exp(-t * 7.0)
                + 0.10 * Math.Sin(ph * 2.81) * Math.Exp(-t * 11.0)
                + 0.06 * Math.Sin(ph * 4.12) * Math.Exp(-t * 13.0);
            s = OnePoleLp(ref lp, s, 0.32);
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
        int n = BeatToSample(durBeats + 0.6);
        double f = MidiHz(midi);
        double g = vel * 0.125;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double drop = 1.0 + 0.01 * Math.Exp(-t * 36.0);
            double e = Math.Exp(-t * 5.1) * (1.0 - Math.Exp(-t * 200.0));
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
        double g = vel * 0.26;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = EnvADSR(t, dur, 0.014, 0.09, 0.68, 0.12);
            double tri = 2.0 * Math.Abs(2.0 * ((f * t) % 1.0) - 1.0) - 1.0;
            double s = 0.74 * Math.Sin(TwoPi * f * t) + 0.26 * tri;
            s = OnePoleLp(ref lp, s, 0.16);
            Mix(L, R, i0 + k, s * e, 0.0, g);
        }
    }

    static void Pad(double[] L, double[] R, double beat, double durBeats, double[] midis, double vel)
    {
        int i0 = BeatToSample(beat);
        double dur = durBeats * 60.0 / Bpm;
        int n = (int)((dur + 0.85) * Sr);
        double g = vel * 0.042;
        for (int m = 0; m < midis.Length; m++)
        {
            double f = MidiHz(midis[m]);
            double pan = (m - (midis.Length - 1) * 0.5) * 0.16;
            for (int d = -1; d <= 1; d++)
            {
                double fd = f * Math.Pow(2.0, d * 0.03 / 12.0);
                for (int k = 0; k < n; k++)
                {
                    double t = k / (double)Sr;
                    double e = EnvADSR(t, dur, 0.5, 0.32, 0.82, 0.75);
                    double s = Math.Sin(TwoPi * fd * t);
                    Mix(L, R, i0 + k, s * e, pan, g);
                }
            }
        }
    }

    static void BellSparkle(double[] L, double[] R, double beat, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = (int)(1.05 * Sr);
        double f = MidiHz(midi);
        double g = vel * 0.085;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 5.8) * (1.0 - Math.Exp(-t * 80));
            double s = Math.Sin(TwoPi * f * t) + 0.45 * Math.Sin(TwoPi * f * 2.013 * t) * Math.Exp(-t * 8);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    // --- ocean ambience -----------------------------------------------------

    static void WaterBed(double[] L, double[] R)
    {
        int n = L.Length;
        double lpL = 0, lpR = 0, lpL2 = 0, lpR2 = 0, rumL = 0, rumR = 0;
        double hpL = 0, hpR = 0;
        for (int i = 0; i < n; i++)
        {
            double ph = i / (double)n;
            double swell1 = 0.42 + 0.58 * (0.5 + 0.5 * Math.Sin(TwoPi * 6.0 * ph));
            double swell2 = 0.38 + 0.62 * (0.5 + 0.5 * Math.Sin(TwoPi * 9.0 * ph + 1.2));
            double swell3 = 0.45 + 0.55 * (0.5 + 0.5 * Math.Sin(TwoPi * 4.0 * ph + 2.4));
            double panW = 0.55 * Math.Sin(TwoPi * 3.0 * ph);

            double nL = Rng.NextDouble() * 2 - 1;
            double nR = Rng.NextDouble() * 2 - 1;
            nL = OnePoleLp(ref lpL, nL, 0.045);
            nR = OnePoleLp(ref lpR, nR, 0.045);
            double foamL = nL - OnePoleLp(ref hpL, nL, 0.018);
            double foamR = nR - OnePoleLp(ref hpR, nR, 0.018);
            double bodyL = OnePoleLp(ref lpL2, nL, 0.09);
            double bodyR = OnePoleLp(ref lpR2, nR, 0.09);
            rumL = OnePoleLp(ref rumL, nL, 0.012);
            rumR = OnePoleLp(ref rumR, nR, 0.012);

            Mix(L, R, i, bodyL * swell1, -0.25 + panW, 0.078);
            Mix(L, R, i, bodyR * swell2, 0.28 + panW * 0.6, 0.072);
            Mix(L, R, i, foamL * swell3, -0.62, 0.032);
            Mix(L, R, i, foamR * swell2, 0.64, 0.030);
            Mix(L, R, i, rumL * (0.5 + 0.5 * swell1), -0.1, 0.048);
            Mix(L, R, i, rumR * (0.5 + 0.5 * swell2), 0.1, 0.048);
        }
    }

    static void FlowCurrent(double[] L, double[] R)
    {
        int n = L.Length;
        double lpL = 0, lpR = 0, bpL = 0, bpR = 0;
        for (int i = 0; i < n; i++)
        {
            double ph = i / (double)n;
            double move = 0.035 + 0.055 * (0.5 + 0.5 * Math.Sin(TwoPi * 7.0 * ph));
            double flow = 0.55 + 0.45 * (0.5 + 0.5 * Math.Sin(TwoPi * 5.0 * ph + 0.4));
            double pan = 0.42 * Math.Sin(TwoPi * 2.0 * ph);
            double nL = Rng.NextDouble() * 2 - 1;
            double nR = Rng.NextDouble() * 2 - 1;
            nL = OnePoleLp(ref lpL, nL, move);
            nR = OnePoleLp(ref lpR, nR, move);
            double cL = nL - OnePoleLp(ref bpL, nL, 0.018);
            double cR = nR - OnePoleLp(ref bpR, nR, 0.018);
            Mix(L, R, i, cL * flow, -0.22 + pan, 0.070);
            Mix(L, R, i, cR * flow, 0.24 + pan * 0.7, 0.066);
        }
    }

    static void WaveWash(double[] L, double[] R, double tSec, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((2.4 + Rng.NextDouble() * 1.2) * Sr);
        double lp = 0, hp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = (1.0 - Math.Exp(-t * 1.6)) * Math.Exp(-t * 0.85);
            double ns = Rng.NextDouble() * 2 - 1;
            ns = OnePoleLp(ref lp, ns, 0.055);
            double foam = ns - OnePoleLp(ref hp, ns, 0.022);
            Mix(L, R, i0 + k, ns * e, pan, amp);
            Mix(L, R, i0 + k, foam * e, pan * 0.65, amp * 0.38);
        }
    }

    static void WaveCrash(double[] L, double[] R, double tSec, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((2.8 + Rng.NextDouble() * 0.8) * Sr);
        double lp = 0, hp = 0, rec = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double hit = (1.0 - Math.Exp(-t * 14.0)) * Math.Exp(-t * 3.4);
            double wash = (1.0 - Math.Exp(-t * 1.1)) * Math.Exp(-t * 0.72);
            double ns = Rng.NextDouble() * 2 - 1;
            ns = OnePoleLp(ref lp, ns, 0.08);
            double hiss = ns - OnePoleLp(ref hp, ns, 0.04);
            rec = OnePoleLp(ref rec, ns, 0.028);
            Mix(L, R, i0 + k, hiss * hit, pan, amp * 1.15);
            Mix(L, R, i0 + k, ns * wash, pan * 0.55, amp * 0.85);
            Mix(L, R, i0 + k, rec * wash, pan * 0.25, amp * 0.70);
        }
    }

    static void SprinkleWater(double[] L, double[] R, double loopSec)
    {
        double t = 0.8;
        while (t < loopSec)
        {
            WaveCrash(L, R, t, (Rng.NextDouble() * 2 - 1) * 0.62, 0.088 + Rng.NextDouble() * 0.028);
            t += 4.2 + Rng.NextDouble() * 2.6;
        }
        t = 0.4;
        while (t < loopSec)
        {
            WaveWash(L, R, t, (Rng.NextDouble() * 2 - 1) * 0.50, 0.038 + Rng.NextDouble() * 0.016);
            t += 1.8 + Rng.NextDouble() * 2.0;
        }
    }

    static void ArpBar(double[] L, double[] R, double barBeat, int[] chord, double vel)
    {
        // Wave-shaped harp: rise then fall
        int[] idx = { 0, 1, 2, 3, 2, 1, 2, 3 };
        for (int i = 0; i < 8; i++)
        {
            double v = vel * (i == 0 || i == 3 ? 1.0 : 0.76);
            Harp(L, R, barBeat + i * 0.5, 0.58, chord[idx[i]], v, (i % 2 == 0) ? -0.14 : 0.18);
        }
    }

    static void BassBar(double[] L, double[] R, double barBeat, int root, bool passing)
    {
        Bass(L, R, barBeat, 2.0, root - 12, 0.88);
        Bass(L, R, barBeat + 2.0, passing ? 1.5 : 2.0, root - 5, 0.70);
        if (passing)
            Bass(L, R, barBeat + 3.5, 0.5, root - 7, 0.52);
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
        int[] taps = { 1423, 1699, 1993, 2441, 3121, 3677 };
        double[] g = { 0.24, 0.19, 0.16, 0.13, 0.10, 0.08 };
        for (int i = 0; i < n; i++)
        {
            double wl = 0, wr = 0;
            for (int t = 0; t < taps.Length; t++)
            {
                int j = Wrap(i - taps[t], n);
                int k = Wrap(i - taps[t] - 223, n);
                wl += l2[j] * g[t] + r2[k] * g[t] * 0.38;
                wr += r2[j] * g[t] + l2[k] * g[t] * 0.38;
            }
            L[i] = l2[i] + wl * 0.42;
            R[i] = r2[i] + wr * 0.42;
        }
    }

    public static void Generate(string path)
    {
        int n = BeatToSample(LoopBeats);
        double loopSec = n / (double)Sr;
        var L = new double[n];
        var R = new double[n];

        WaterBed(L, R);
        FlowCurrent(L, R);
        SprinkleWater(L, R, loopSec);

        int[] D  = { 62, 66, 69, 74 };
        int[] Bm = { 59, 62, 66, 71 };
        int[] G  = { 55, 59, 62, 67 };
        int[] A  = { 57, 61, 64, 69 };
        int[] Fsm = { 66, 69, 73, 78 };
        int[] Em = { 64, 67, 71, 76 };

        int[][] progA = { D, Bm, G, A, D, Fsm, G, A };
        int[][] progB = { G, D, Em, A, G, Bm, Em, A };

        Pad(L, R, 0, 8, new double[] { 50, 54, 57, 62 }, 0.78);
        ArpBar(L, R, 0, D, 0.58);
        ArpBar(L, R, 4, D, 0.64);
        BassBar(L, R, 0, 62, false);
        BassBar(L, R, 4, 62, false);
        BellSparkle(L, R, 1.0, 86, 0.48, 0.38);
        BellSparkle(L, R, 5.5, 81, 0.40, -0.32);

        Action<double, int[][], double> arrange = (startBeat, prog, padVel) =>
        {
            for (int b = 0; b < prog.Length; b++)
            {
                double beat = startBeat + b * 4.0;
                int[] ch = prog[b];
                Pad(L, R, beat, 4.0, new double[] { ch[0] - 12, ch[1] - 12, ch[2] - 12, ch[0] }, padVel);
                ArpBar(L, R, beat, ch, 0.72);
                BassBar(L, R, beat, ch[0], b % 4 == 3);
            }
        };

        arrange(8, progA, 0.86);
        arrange(40, progB, 0.48);

        // A: music-box, D major pastoral ocean
        Kalimba(L, R,  8.00, 0.5, 69, 0.70, 0.16);
        Kalimba(L, R,  8.50, 0.5, 74, 0.72, 0.14);
        Kalimba(L, R,  9.00, 1.0, 78, 0.88, 0.10);
        Kalimba(L, R, 10.00, 0.5, 76, 0.64, 0.14);
        Kalimba(L, R, 10.50, 0.5, 74, 0.62, 0.16);
        Kalimba(L, R, 11.00, 1.0, 69, 0.76, 0.10);

        Kalimba(L, R, 12.00, 0.5, 66, 0.66, 0.18);
        Kalimba(L, R, 12.50, 0.5, 69, 0.66, 0.16);
        Kalimba(L, R, 13.00, 1.0, 74, 0.82, 0.12);
        Kalimba(L, R, 14.00, 0.5, 71, 0.62, 0.14);
        Kalimba(L, R, 14.50, 0.5, 69, 0.62, 0.16);
        Kalimba(L, R, 15.00, 1.0, 62, 0.74, 0.08);

        Kalimba(L, R, 16.00, 0.5, 67, 0.64, 0.16);
        Kalimba(L, R, 16.50, 0.5, 71, 0.66, 0.14);
        Kalimba(L, R, 17.00, 1.0, 74, 0.82, 0.10);
        Kalimba(L, R, 18.00, 0.75, 79, 0.80, 0.08);
        Kalimba(L, R, 18.75, 0.25, 78, 0.58, 0.14);
        Kalimba(L, R, 19.00, 0.5, 76, 0.64, 0.16);
        Kalimba(L, R, 19.50, 0.5, 74, 0.62, 0.18);

        Kalimba(L, R, 20.00, 0.5, 73, 0.70, 0.14);
        Kalimba(L, R, 20.50, 0.5, 69, 0.62, 0.18);
        Kalimba(L, R, 21.00, 0.5, 73, 0.68, 0.14);
        Kalimba(L, R, 21.50, 1.0, 76, 0.86, 0.10);
        Kalimba(L, R, 22.50, 0.5, 74, 0.64, 0.14);
        Kalimba(L, R, 23.00, 0.5, 73, 0.70, 0.12);
        Kalimba(L, R, 23.50, 0.5, 69, 0.58, 0.16);

        Kalimba(L, R, 24.00, 0.5, 74, 0.76, 0.12);
        Kalimba(L, R, 24.50, 0.5, 76, 0.74, 0.12);
        Kalimba(L, R, 25.00, 0.75, 78, 0.90, 0.08);
        Kalimba(L, R, 25.75, 0.25, 81, 0.72, 0.18);
        Kalimba(L, R, 26.00, 1.0, 86, 0.86, 0.04);
        Kalimba(L, R, 27.00, 0.5, 81, 0.70, 0.12);
        Kalimba(L, R, 27.50, 0.5, 78, 0.72, 0.10);

        Kalimba(L, R, 28.00, 0.5, 73, 0.72, 0.14);
        Kalimba(L, R, 28.50, 0.5, 69, 0.66, 0.16);
        Kalimba(L, R, 29.00, 1.0, 66, 0.76, 0.10);
        Kalimba(L, R, 30.00, 0.5, 69, 0.64, 0.14);
        Kalimba(L, R, 30.50, 0.5, 73, 0.66, 0.12);
        Kalimba(L, R, 31.00, 1.0, 74, 0.72, 0.10);

        Kalimba(L, R, 32.00, 0.5, 67, 0.70, 0.14);
        Kalimba(L, R, 32.50, 0.5, 71, 0.72, 0.12);
        Kalimba(L, R, 33.00, 1.0, 74, 0.84, 0.08);
        Kalimba(L, R, 34.00, 0.5, 79, 0.70, 0.14);
        Kalimba(L, R, 34.50, 0.5, 76, 0.64, 0.16);
        Kalimba(L, R, 35.00, 1.0, 71, 0.70, 0.10);

        Kalimba(L, R, 36.00, 0.5, 73, 0.74, 0.12);
        Kalimba(L, R, 36.50, 0.5, 76, 0.70, 0.14);
        Kalimba(L, R, 37.00, 1.0, 81, 0.86, 0.08);
        Kalimba(L, R, 38.00, 0.5, 78, 0.66, 0.14);
        Kalimba(L, R, 38.50, 0.5, 76, 0.72, 0.12);
        Kalimba(L, R, 39.00, 0.5, 74, 0.64, 0.16);
        Kalimba(L, R, 39.50, 0.5, 73, 0.60, 0.18);

        BellSparkle(L, R, 9.05, 93, 0.34, 0.52);
        BellSparkle(L, R, 25.1, 98, 0.30, -0.42);
        BellSparkle(L, R, 33.1, 93, 0.28, 0.48);

        // B: bright whistle over open water (no low hummed long tones)
        Flute(L, R, 40.00, 1.0, 74, 0.82, -0.22);
        Flute(L, R, 41.00, 1.0, 79, 0.84, -0.20);
        Flute(L, R, 42.00, 1.5, 86, 0.90, -0.14);
        Flute(L, R, 43.50, 0.5, 83, 0.70, -0.18);
        Flute(L, R, 44.00, 1.0, 81, 0.80, -0.20);
        Flute(L, R, 45.00, 0.5, 78, 0.70, -0.22);
        Flute(L, R, 45.50, 0.5, 74, 0.68, -0.20);
        Flute(L, R, 46.00, 1.0, 81, 0.74, -0.16);
        Flute(L, R, 47.00, 1.0, 78, 0.70, -0.18);

        Flute(L, R, 48.00, 0.5, 76, 0.72, -0.22);
        Flute(L, R, 48.50, 0.5, 74, 0.72, -0.20);
        Flute(L, R, 49.00, 1.0, 76, 0.82, -0.18);
        Flute(L, R, 50.00, 1.0, 79, 0.84, -0.16);
        Flute(L, R, 51.00, 1.0, 76, 0.76, -0.20);
        Flute(L, R, 52.00, 1.0, 81, 0.78, -0.18);
        Flute(L, R, 53.00, 1.0, 76, 0.80, -0.18);
        Flute(L, R, 54.00, 1.0, 81, 0.74, -0.16);
        Flute(L, R, 55.00, 1.0, 78, 0.70, -0.16);

        Flute(L, R, 56.00, 0.5, 79, 0.74, -0.20);
        Flute(L, R, 56.50, 0.5, 83, 0.76, -0.18);
        Flute(L, R, 57.00, 1.0, 86, 0.86, -0.16);
        Flute(L, R, 58.00, 1.0, 81, 0.84, -0.14);
        Flute(L, R, 59.00, 0.5, 78, 0.72, -0.18);
        Flute(L, R, 59.50, 0.5, 76, 0.70, -0.20);
        Flute(L, R, 60.00, 0.5, 74, 0.74, -0.18);
        Flute(L, R, 60.50, 0.5, 78, 0.72, -0.16);
        Flute(L, R, 61.00, 1.0, 81, 0.80, -0.16);
        Flute(L, R, 62.00, 0.5, 74, 0.74, -0.18);
        Flute(L, R, 62.50, 0.5, 76, 0.74, -0.16);
        Flute(L, R, 63.00, 1.0, 81, 0.78, -0.14);

        Flute(L, R, 64.00, 1.0, 86, 0.80, -0.16);
        Flute(L, R, 65.00, 0.5, 83, 0.70, -0.18);
        Flute(L, R, 65.50, 0.5, 79, 0.68, -0.20);
        Flute(L, R, 66.00, 0.5, 74, 0.72, -0.18);
        Flute(L, R, 66.50, 0.5, 78, 0.74, -0.16);
        Flute(L, R, 67.00, 1.0, 81, 0.78, -0.14);
        Flute(L, R, 68.00, 0.5, 81, 0.74, -0.16);
        Flute(L, R, 68.50, 0.5, 85, 0.76, -0.14);
        Flute(L, R, 69.00, 1.0, 86, 0.84, -0.12);
        Flute(L, R, 70.00, 1.0, 81, 0.80, -0.14);
        Flute(L, R, 71.00, 0.5, 78, 0.70, -0.16);
        Flute(L, R, 71.50, 0.5, 74, 0.72, -0.14);

        Kalimba(L, R, 42.05, 0.4, 86, 0.34, 0.46);
        Kalimba(L, R, 50.05, 0.4, 93, 0.30, 0.50);
        Kalimba(L, R, 58.05, 0.5, 98, 0.28, 0.40);

        Reverb(L, R);

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
        Console.WriteLine("Duration {0:0.00}s  BPM {1}  seamless loop", loopSec, Bpm);
    }
}

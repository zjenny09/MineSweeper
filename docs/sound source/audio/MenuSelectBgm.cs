using System;
using System.IO;

/// <summary>
/// Mode-select / title menu BGM. Nintendo paper-cut, not tied to one biome.
/// Circular buffer for a seamless loop under the UI.
/// </summary>
public static class MenuSelectBgm
{
    const int Sr = 44100;
    const double Bpm = 90.0;
    const double TwoPi = Math.PI * 2.0;
    const double LoopBeats = 64.0; // 16 bars

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
        int n = BeatToSample(durBeats + 1.05);
        double f = MidiHz(midi);
        double g = vel * 0.20;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 3.15) * (1.0 - Math.Exp(-t * 170.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.30 * Math.Sin(ph * 2.004) * Math.Exp(-t * 6.8)
                + 0.10 * Math.Sin(ph * 2.81) * Math.Exp(-t * 11.0)
                + 0.06 * Math.Sin(ph * 4.10) * Math.Exp(-t * 13.0);
            s = OnePoleLp(ref lp, s, 0.30);
            Mix(L, R, i0 + k, s * e, pan, g);
        }
    }

    static void Harp(double[] L, double[] R, double beat, double durBeats, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = BeatToSample(durBeats + 0.55);
        double f = MidiHz(midi);
        double g = vel * 0.11;
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double drop = 1.0 + 0.01 * Math.Exp(-t * 36.0);
            double e = Math.Exp(-t * 5.2) * (1.0 - Math.Exp(-t * 200.0));
            double ph = TwoPi * f * drop * t;
            double s = Math.Sin(ph) + 0.18 * Math.Sin(ph * 2.0) * Math.Exp(-t * 8)
                + 0.06 * Math.Sin(ph * 3.02) * Math.Exp(-t * 12);
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
        int n = (int)((dur + 0.8) * Sr);
        double g = vel * 0.036;
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
                    double e = EnvADSR(t, dur, 0.5, 0.3, 0.80, 0.75);
                    Mix(L, R, i0 + k, Math.Sin(TwoPi * fd * t) * e, pan, g);
                }
            }
        }
    }

    static void Sparkle(double[] L, double[] R, double beat, double midi, double vel, double pan)
    {
        int i0 = BeatToSample(beat);
        int n = (int)(0.95 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 5.6) * (1.0 - Math.Exp(-t * 80));
            double s = Math.Sin(TwoPi * f * t) + 0.4 * Math.Sin(TwoPi * f * 2.01 * t) * Math.Exp(-t * 8);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.085);
        }
    }

    static void ArpBar(double[] L, double[] R, double barBeat, int[] chord, double vel)
    {
        int[] idx = { 0, 1, 2, 3, 2, 1, 2, 3 };
        for (int i = 0; i < 8; i++)
        {
            double v = vel * (i == 0 || i == 3 ? 1.0 : 0.76);
            Harp(L, R, barBeat + i * 0.5, 0.52, chord[idx[i]], v, (i % 2 == 0) ? -0.14 : 0.18);
        }
    }

    static void BassBar(double[] L, double[] R, double barBeat, int root, bool passing)
    {
        Bass(L, R, barBeat, 2.0, root - 12, 0.80);
        Bass(L, R, barBeat + 2.0, passing ? 1.5 : 2.0, root - 5, 0.62);
        if (passing)
            Bass(L, R, barBeat + 3.5, 0.5, root - 7, 0.48);
    }

    static void Reverb(double[] L, double[] R)
    {
        int n = L.Length;
        var l2 = (double[])L.Clone();
        var r2 = (double[])R.Clone();
        int[] taps = { 1409, 1693, 1997, 2473, 3181, 3709 };
        double[] g = { 0.22, 0.18, 0.15, 0.12, 0.09, 0.07 };
        for (int i = 0; i < n; i++)
        {
            double wl = 0, wr = 0;
            for (int t = 0; t < taps.Length; t++)
            {
                int j = Wrap(i - taps[t], n);
                int k = Wrap(i - taps[t] - 223, n);
                wl += l2[j] * g[t] + r2[k] * g[t] * 0.36;
                wr += r2[j] * g[t] + l2[k] * g[t] * 0.36;
            }
            L[i] = l2[i] + wl * 0.40;
            R[i] = r2[i] + wr * 0.40;
        }
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
        double norm = 0.88 / peak;
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
                short sl = (short)Clamp(Math.Tanh(L[i] * norm * 1.02) * 32767.0, -32767, 32767);
                short sr = (short)Clamp(Math.Tanh(R[i] * norm * 1.02) * 32767.0, -32767, 32767);
                bw.Write(sl);
                bw.Write(sr);
            }
        }
    }

    public static void Generate(string path)
    {
        int n = BeatToSample(LoopBeats);
        double loopSec = n / (double)Sr;
        var L = new double[n];
        var R = new double[n];

        int[] C  = { 60, 64, 67, 72 };
        int[] G  = { 55, 59, 62, 67 };
        int[] Am = { 57, 60, 64, 69 };
        int[] F  = { 53, 57, 60, 65 };
        int[] Em = { 52, 55, 59, 64 };

        int[][] progA = { C, G, Am, F, C, Em, F, G };
        int[][] progB = { Am, Em, F, G, C, G, F, G };

        Action<double, int[][], double> arrange = (startBeat, prog, padVel) =>
        {
            for (int b = 0; b < prog.Length; b++)
            {
                double beat = startBeat + b * 4.0;
                int[] ch = prog[b];
                Pad(L, R, beat, 4.0, new double[] { ch[0] - 12, ch[1] - 12, ch[2] - 12, ch[0] }, padVel);
                ArpBar(L, R, beat, ch, 0.66);
                BassBar(L, R, beat, ch[0], b % 4 == 3);
            }
        };

        arrange(0, progA, 0.78);
        arrange(32, progB, 0.50);

        // A: welcome motif
        Kalimba(L, R,  0.00, 0.5, 76, 0.70, 0.14);
        Kalimba(L, R,  0.50, 0.5, 79, 0.72, 0.12);
        Kalimba(L, R,  1.00, 1.0, 84, 0.86, 0.08);
        Kalimba(L, R,  2.00, 0.5, 81, 0.64, 0.14);
        Kalimba(L, R,  2.50, 0.5, 79, 0.62, 0.16);
        Kalimba(L, R,  3.00, 1.0, 76, 0.74, 0.10);

        Kalimba(L, R,  4.00, 0.5, 74, 0.66, 0.16);
        Kalimba(L, R,  4.50, 0.5, 76, 0.66, 0.14);
        Kalimba(L, R,  5.00, 1.0, 79, 0.80, 0.10);
        Kalimba(L, R,  6.00, 0.5, 76, 0.62, 0.14);
        Kalimba(L, R,  6.50, 0.5, 74, 0.62, 0.16);
        Kalimba(L, R,  7.00, 1.0, 71, 0.72, 0.08);

        Kalimba(L, R,  8.00, 0.5, 72, 0.68, 0.14);
        Kalimba(L, R,  8.50, 0.5, 76, 0.70, 0.12);
        Kalimba(L, R,  9.00, 1.0, 81, 0.84, 0.08);
        Kalimba(L, R, 10.00, 0.75, 84, 0.78, 0.10);
        Kalimba(L, R, 10.75, 0.25, 83, 0.56, 0.16);
        Kalimba(L, R, 11.00, 0.5, 81, 0.64, 0.14);
        Kalimba(L, R, 11.50, 0.5, 79, 0.62, 0.16);

        Kalimba(L, R, 12.00, 0.5, 79, 0.72, 0.12);
        Kalimba(L, R, 12.50, 0.5, 76, 0.64, 0.16);
        Kalimba(L, R, 13.00, 0.5, 79, 0.68, 0.12);
        Kalimba(L, R, 13.50, 1.0, 83, 0.84, 0.08);
        Kalimba(L, R, 14.50, 0.5, 81, 0.64, 0.14);
        Kalimba(L, R, 15.00, 0.5, 79, 0.70, 0.12);
        Kalimba(L, R, 15.50, 0.5, 76, 0.58, 0.16);

        Kalimba(L, R, 16.00, 0.5, 76, 0.74, 0.12);
        Kalimba(L, R, 16.50, 0.5, 79, 0.74, 0.10);
        Kalimba(L, R, 17.00, 0.75, 84, 0.90, 0.06);
        Kalimba(L, R, 17.75, 0.25, 86, 0.70, 0.18);
        Kalimba(L, R, 18.00, 1.0, 88, 0.86, 0.04);
        Kalimba(L, R, 19.00, 0.5, 84, 0.70, 0.12);
        Kalimba(L, R, 19.50, 0.5, 81, 0.72, 0.10);

        Kalimba(L, R, 20.00, 0.5, 79, 0.70, 0.14);
        Kalimba(L, R, 20.50, 0.5, 76, 0.66, 0.16);
        Kalimba(L, R, 21.00, 1.0, 71, 0.74, 0.10);
        Kalimba(L, R, 22.00, 0.5, 74, 0.64, 0.14);
        Kalimba(L, R, 22.50, 0.5, 76, 0.66, 0.12);
        Kalimba(L, R, 23.00, 1.0, 79, 0.72, 0.10);

        Kalimba(L, R, 24.00, 0.5, 77, 0.70, 0.14);
        Kalimba(L, R, 24.50, 0.5, 81, 0.72, 0.12);
        Kalimba(L, R, 25.00, 1.0, 84, 0.84, 0.08);
        Kalimba(L, R, 26.00, 0.5, 81, 0.68, 0.14);
        Kalimba(L, R, 26.50, 0.5, 77, 0.64, 0.16);
        Kalimba(L, R, 27.00, 1.0, 72, 0.70, 0.10);

        Kalimba(L, R, 28.00, 0.5, 79, 0.74, 0.12);
        Kalimba(L, R, 28.50, 0.5, 81, 0.70, 0.14);
        Kalimba(L, R, 29.00, 1.0, 83, 0.84, 0.08);
        Kalimba(L, R, 30.00, 0.5, 81, 0.66, 0.14);
        Kalimba(L, R, 30.50, 0.5, 79, 0.72, 0.12);
        Kalimba(L, R, 31.00, 0.5, 76, 0.64, 0.16);
        Kalimba(L, R, 31.50, 0.5, 74, 0.58, 0.18);

        Sparkle(L, R, 1.05, 96, 0.34, 0.48);
        Sparkle(L, R, 17.1, 100, 0.30, -0.42);
        Sparkle(L, R, 25.1, 96, 0.28, 0.40);

        // B: answering phrase, still music-box (keeps the menu airy)
        Kalimba(L, R, 32.00, 0.5, 81, 0.70, -0.10);
        Kalimba(L, R, 32.50, 0.5, 84, 0.72, -0.08);
        Kalimba(L, R, 33.00, 1.0, 88, 0.84, -0.04);
        Kalimba(L, R, 34.00, 0.5, 86, 0.66, -0.08);
        Kalimba(L, R, 34.50, 0.5, 84, 0.64, -0.10);
        Kalimba(L, R, 35.00, 1.0, 81, 0.74, -0.06);

        Kalimba(L, R, 36.00, 0.5, 79, 0.68, -0.12);
        Kalimba(L, R, 36.50, 0.5, 76, 0.66, -0.10);
        Kalimba(L, R, 37.00, 1.0, 79, 0.78, -0.08);
        Kalimba(L, R, 38.00, 1.0, 83, 0.80, -0.06);
        Kalimba(L, R, 39.00, 1.0, 79, 0.72, -0.10);

        Kalimba(L, R, 40.00, 0.5, 77, 0.70, -0.10);
        Kalimba(L, R, 40.50, 0.5, 81, 0.72, -0.08);
        Kalimba(L, R, 41.00, 1.0, 84, 0.84, -0.06);
        Kalimba(L, R, 42.00, 1.0, 88, 0.82, -0.04);
        Kalimba(L, R, 43.00, 0.5, 86, 0.68, -0.08);
        Kalimba(L, R, 43.50, 0.5, 84, 0.66, -0.10);

        Kalimba(L, R, 44.00, 0.5, 83, 0.74, -0.08);
        Kalimba(L, R, 44.50, 0.5, 81, 0.70, -0.10);
        Kalimba(L, R, 45.00, 1.0, 79, 0.78, -0.08);
        Kalimba(L, R, 46.00, 1.0, 76, 0.74, -0.06);
        Kalimba(L, R, 47.00, 1.0, 74, 0.68, -0.08);

        Kalimba(L, R, 48.00, 0.5, 76, 0.72, 0.08);
        Kalimba(L, R, 48.50, 0.5, 79, 0.74, 0.06);
        Kalimba(L, R, 49.00, 1.0, 84, 0.86, 0.04);
        Kalimba(L, R, 50.00, 0.5, 81, 0.68, 0.10);
        Kalimba(L, R, 50.50, 0.5, 79, 0.66, 0.12);
        Kalimba(L, R, 51.00, 1.0, 76, 0.74, 0.06);

        Kalimba(L, R, 52.00, 0.5, 74, 0.68, 0.10);
        Kalimba(L, R, 52.50, 0.5, 76, 0.70, 0.08);
        Kalimba(L, R, 53.00, 1.0, 79, 0.80, 0.06);
        Kalimba(L, R, 54.00, 1.0, 83, 0.78, 0.04);
        Kalimba(L, R, 55.00, 1.0, 79, 0.70, 0.08);

        Kalimba(L, R, 56.00, 0.5, 77, 0.70, 0.10);
        Kalimba(L, R, 56.50, 0.5, 81, 0.72, 0.08);
        Kalimba(L, R, 57.00, 1.0, 84, 0.82, 0.04);
        Kalimba(L, R, 58.00, 0.5, 83, 0.68, 0.10);
        Kalimba(L, R, 58.50, 0.5, 81, 0.66, 0.12);
        Kalimba(L, R, 59.00, 1.0, 79, 0.72, 0.08);

        Kalimba(L, R, 60.00, 0.5, 76, 0.70, 0.10);
        Kalimba(L, R, 60.50, 0.5, 79, 0.72, 0.08);
        Kalimba(L, R, 61.00, 1.0, 81, 0.80, 0.04);
        Kalimba(L, R, 62.00, 0.5, 79, 0.66, 0.10);
        Kalimba(L, R, 62.50, 0.5, 76, 0.68, 0.08);
        Kalimba(L, R, 63.00, 1.0, 72, 0.74, 0.04);

        Sparkle(L, R, 33.05, 100, 0.30, 0.46);
        Sparkle(L, R, 49.1, 96, 0.28, -0.38);
        Sparkle(L, R, 61.1, 103, 0.26, 0.20);

        Reverb(L, R);
        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
        Console.WriteLine("Duration {0:0.00}s  BPM {1}  seamless loop", loopSec, Bpm);
    }
}

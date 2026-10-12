using System;
using System.IO;

/// <summary>
/// Ocean/aquarium minesweeper win sting: pearl rising through water, then a surface sparkle.
/// </summary>
public static class AquariumWinSfx
{
    const int Sr = 44100;
    const double TwoPi = Math.PI * 2.0;
    static readonly Random Rng = new Random(21);

    static double MidiHz(double midi)
    {
        return 440.0 * Math.Pow(2.0, (midi - 69.0) / 12.0);
    }

    static double Clamp(double x, double lo, double hi)
    {
        return x < lo ? lo : (x > hi ? hi : x);
    }

    static void Mix(double[] L, double[] R, int i, double s, double pan, double gain)
    {
        if (i < 0 || i >= L.Length) return;
        double pl = Math.Cos((pan + 1.0) * Math.PI * 0.25);
        double pr = Math.Sin((pan + 1.0) * Math.PI * 0.25);
        L[i] += s * pl * gain;
        R[i] += s * pr * gain;
    }

    static void Bell(double[] L, double[] R, double tSec, double midi, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(1.4 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 2.9) * (1.0 - Math.Exp(-t * 80.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.28 * Math.Sin(ph * 2.003) * Math.Exp(-t * 6.8)
                + 0.08 * Math.Sin(ph * 2.81) * Math.Exp(-t * 11.0);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.21);
        }
    }

    static void Drop(double[] L, double[] R, double tSec, double f0, double f1, double dur, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = Math.Max(12, (int)(dur * Sr));
        double phase = 0;
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double u = k / (double)(n - 1);
            double f = f0 * Math.Pow(f1 / f0, Math.Pow(u, 0.7));
            phase += TwoPi * f / Sr;
            double e = (1.0 - Math.Exp(-u * 16)) * Math.Exp(-u * 4.8);
            Mix(L, R, i0 + k, Math.Sin(phase) * e, pan, amp);
        }
    }

    static void Pad(double[] L, double[] R, double tSec, double midi, double dur, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((dur + 0.55) * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double a = t < 0.22 ? t / 0.22 : 1.0;
            double r = t > dur ? 1.0 - (t - dur) / 0.55 : 1.0;
            if (r < 0) r = 0;
            Mix(L, R, i0 + k, Math.Sin(TwoPi * f * t) * a * r, pan, vel * 0.048);
        }
    }

    static void WaterBed(double[] L, double[] R, int n)
    {
        double lp = 0, hp = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / (double)Sr;
            double e = (1.0 - Math.Exp(-t * 6.0)) * Math.Exp(-t * 1.7);
            double ns = Rng.NextDouble() * 2 - 1;
            lp += 0.05 * (ns - lp);
            hp += 0.018 * (lp - hp);
            Mix(L, R, i, (lp - hp) * e, -0.2 + 0.35 * Math.Min(t * 0.7, 1), 0.085);
        }
    }

    static void Splash(double[] L, double[] R, double tSec, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.32 * Sr);
        double lp = 0, hp = 0;
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = (1.0 - Math.Exp(-t * 18)) * Math.Exp(-t * 8);
            double ns = Rng.NextDouble() * 2 - 1;
            lp += 0.12 * (ns - lp);
            hp += 0.04 * (lp - hp);
            Mix(L, R, i0 + k, (lp - hp) * e, pan, amp);
        }
    }

    static void WriteWav(string path, double[] L, double[] R)
    {
        int nn = L.Length;
        double peak = 1e-9;
        for (int i = 0; i < nn; i++)
        {
            peak = Math.Max(peak, Math.Abs(L[i]));
            peak = Math.Max(peak, Math.Abs(R[i]));
        }
        double norm = 0.88 / peak;
        using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write))
        using (var bw = new BinaryWriter(fs))
        {
            int dataBytes = nn * 4;
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
            for (int i = 0; i < nn; i++)
            {
                short sl = (short)Clamp(Math.Tanh(L[i] * norm) * 32767.0, -32767, 32767);
                short sr = (short)Clamp(Math.Tanh(R[i] * norm) * 32767.0, -32767, 32767);
                bw.Write(sl);
                bw.Write(sr);
            }
        }
    }

    public static void Generate(string path)
    {
        int n = (int)(2.50 * Sr);
        var L = new double[n];
        var R = new double[n];

        WaterBed(L, R, n);

        // Deep water pad in D major (same world as ocean BGM)
        Pad(L, R, 0.00, 50, 1.8, 0.80, -0.10);
        Pad(L, R, 0.00, 57, 1.9, 0.78, 0.12);
        Pad(L, R, 0.00, 62, 2.0, 0.74, 0.00);

        // Pearl rising: D F# A D F# A
        Bell(L, R, 0.08, 62, 0.68, -0.28);
        Bell(L, R, 0.22, 66, 0.72, -0.14);
        Bell(L, R, 0.36, 69, 0.78, 0.00);
        Bell(L, R, 0.50, 74, 0.86, 0.16);
        Bell(L, R, 0.64, 78, 0.84, 0.28);
        Bell(L, R, 0.78, 81, 0.76, 0.10);

        // Light droplets beside the rise
        Drop(L, R, 0.18, 720, 1280, 0.08, -0.40, 0.18);
        Drop(L, R, 0.40, 820, 1500, 0.08, 0.36, 0.16);
        Drop(L, R, 0.58, 900, 1680, 0.07, -0.22, 0.15);

        // Breaks the surface
        Splash(L, R, 0.88, 0.06, 0.22);
        Bell(L, R, 0.90, 86, 0.90, 0.04);
        Bell(L, R, 1.02, 90, 0.62, 0.32);
        Drop(L, R, 0.94, 1400, 2400, 0.10, 0.12, 0.22);

        // Sunlit D major bloom
        Pad(L, R, 0.92, 66, 1.35, 0.88, -0.14);
        Pad(L, R, 0.92, 69, 1.40, 0.86, 0.00);
        Pad(L, R, 0.92, 74, 1.45, 0.84, 0.14);
        Pad(L, R, 0.92, 78, 1.50, 0.70, 0.06);

        // Victory tag over water
        Bell(L, R, 1.22, 74, 0.72, -0.10);
        Bell(L, R, 1.38, 78, 0.78, 0.08);
        Bell(L, R, 1.58, 86, 0.88, 0.04);
        Drop(L, R, 1.62, 1100, 1900, 0.09, 0.20, 0.14);

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }
}

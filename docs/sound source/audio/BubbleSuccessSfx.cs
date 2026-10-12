using System;
using System.IO;

/// <summary>
/// Short bubble pop for minesweeper cell click.
/// </summary>
public static class BubbleSuccessSfx
{
    const int Sr = 44100;
    const double TwoPi = Math.PI * 2.0;

    static double Clamp(double x, double lo, double hi)
    {
        return x < lo ? lo : (x > hi ? hi : x);
    }

    static double Lerp(double a, double b, double t)
    {
        return a + (b - a) * t;
    }

    static void Mix(double[] L, double[] R, int i, double s, double pan, double gain)
    {
        if (i < 0 || i >= L.Length) return;
        double pl = Math.Cos((pan + 1.0) * Math.PI * 0.25);
        double pr = Math.Sin((pan + 1.0) * Math.PI * 0.25);
        L[i] += s * pl * gain;
        R[i] += s * pr * gain;
    }

    static void Bubble(double[] L, double[] R, double tSec, double f0, double f1, double dur, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = Math.Max(8, (int)(dur * Sr));
        for (int k = 0; k < n; k++)
        {
            double u = k / (double)(n - 1);
            double f = Lerp(f0, f1, u * u);
            double e = Math.Sin(Math.PI * Math.Pow(u, 0.65));
            double t = k / (double)Sr;
            double s = Math.Sin(TwoPi * f * t)
                + 0.22 * Math.Sin(TwoPi * f * 2.03 * t) * (1.0 - u);
            Mix(L, R, i0 + k, s * e, pan, amp);
        }
    }

    static void TinySplash(double[] L, double[] R, double tSec, double pan, double amp)
    {
        var rng = new Random(42);
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.07 * Sr);
        double lp = 0;
        for (int k = 0; k < n; k++)
        {
            double u = k / (double)Math.Max(n - 1, 1);
            double e = Math.Exp(-u * 7.0) * (1.0 - Math.Exp(-u * 40));
            double ns = rng.NextDouble() * 2 - 1;
            lp += 0.18 * (ns - lp);
            Mix(L, R, i0 + k, lp * e, pan, amp);
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
        double norm = 0.86 / peak;
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
                short sl = (short)Clamp(Math.Tanh(L[i] * norm) * 32767.0, -32767, 32767);
                short sr = (short)Clamp(Math.Tanh(R[i] * norm) * 32767.0, -32767, 32767);
                bw.Write(sl);
                bw.Write(sr);
            }
        }
    }

    static void Blub(double[] L, double[] R, double tSec, double f0, double f1, double dur, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = Math.Max(16, (int)(dur * Sr));
        double phase = 0;
        for (int k = 0; k < n; k++)
        {
            double u = k / (double)(n - 1);
            double f = f0 * Math.Pow(f1 / f0, Math.Pow(u, 0.62));
            phase += TwoPi * f / Sr;
            double att = 1.0 - Math.Exp(-u * 18.0);
            double dec = Math.Exp(-Math.Max(0, u - 0.18) * 4.2);
            double e = att * dec;
            double s = Math.Sin(phase)
                + 0.08 * Math.Sin(phase * 2.0) * (1.0 - u);
            Mix(L, R, i0 + k, s * e, pan, amp);
        }
    }

    public static void Generate(string path)
    {
        var rng = new Random(11);
        int n = (int)(0.28 * Sr);
        var L = new double[n];
        var R = new double[n];
        double lp = 0, hp = 0;

        // Immediate foam tick so the click feels instant
        int tick = (int)(0.018 * Sr);
        for (int k = 0; k < tick; k++)
        {
            double u = k / (double)Math.Max(tick - 1, 1);
            double e = (1.0 - u) * (1.0 - Math.Exp(-u * 40));
            double ns = rng.NextDouble() * 2 - 1;
            lp += 0.22 * (ns - lp);
            hp += 0.06 * (lp - hp);
            Mix(L, R, k, (lp - hp) * e, 0.0, 0.42);
        }

        // Main sea-bubble pop
        {
            int i0 = (int)(0.004 * Sr);
            int bn = (int)(0.09 * Sr);
            double phase = 0;
            for (int k = 0; k < bn; k++)
            {
                double u = k / (double)(bn - 1);
                double f = 620 * Math.Pow(2.15, Math.Pow(u, 0.7));
                phase += TwoPi * f / Sr;
                double e = (1.0 - Math.Exp(-u * 22)) * Math.Exp(-u * 5.5);
                Mix(L, R, i0 + k, Math.Sin(phase) * e, -0.08, 0.58);
            }
        }

        // Second smaller foam pop
        {
            int i0 = (int)(0.055 * Sr);
            int bn = (int)(0.07 * Sr);
            double phase = 0;
            for (int k = 0; k < bn; k++)
            {
                double u = k / (double)(bn - 1);
                double f = 880 * Math.Pow(1.85, Math.Pow(u, 0.7));
                phase += TwoPi * f / Sr;
                double e = (1.0 - Math.Exp(-u * 20)) * Math.Exp(-u * 6.2);
                Mix(L, R, i0 + k, Math.Sin(phase) * e, 0.16, 0.32);
            }
        }

        // Short fizz tail, dies quickly so rapid clicks stay clean
        double lp2 = 0, hp2 = 0;
        for (int k = 0; k < n; k++)
        {
            double t = k / (double)Sr;
            if (t < 0.03) continue;
            double e = Math.Exp(-(t - 0.03) * 14.0);
            double ns = rng.NextDouble() * 2 - 1;
            lp2 += 0.10 * (ns - lp2);
            hp2 += 0.04 * (lp2 - hp2);
            Mix(L, R, k, (lp2 - hp2) * e, 0.05, 0.14);
        }

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }
}

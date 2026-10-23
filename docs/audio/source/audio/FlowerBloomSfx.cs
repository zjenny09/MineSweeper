using System;
using System.IO;

/// <summary>
/// Minesweeper win sting: Nintendo-like flower blooming celebration.
/// </summary>
public static class FlowerBloomSfx
{
    const int Sr = 44100;
    const double TwoPi = Math.PI * 2.0;

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

    static void Petal(double[] L, double[] R, double tSec, double midi, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(1.35 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 3.1) * (1.0 - Math.Exp(-t * 90.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.32 * Math.Sin(ph * 2.004) * Math.Exp(-t * 6.5)
                + 0.10 * Math.Sin(ph * 2.76) * Math.Exp(-t * 10.0)
                + 0.06 * Math.Sin(ph * 4.08) * Math.Exp(-t * 13.0);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.22);
        }
    }

    static void Sparkle(double[] L, double[] R, double tSec, double midi, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.7 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 6.2) * (1.0 - Math.Exp(-t * 70));
            double s = Math.Sin(TwoPi * f * t) + 0.4 * Math.Sin(TwoPi * f * 2.01 * t) * Math.Exp(-t * 8);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.10);
        }
    }

    static void Pad(double[] L, double[] R, double tSec, double midi, double dur, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((dur + 0.5) * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double a = t < 0.18 ? t / 0.18 : 1.0;
            double r = t > dur ? 1.0 - (t - dur) / 0.5 : 1.0;
            if (r < 0) r = 0;
            double e = a * r;
            Mix(L, R, i0 + k, Math.Sin(TwoPi * f * t) * e, pan, vel * 0.05);
        }
    }

    static void Unfold(double[] L, double[] R, int n)
    {
        var rng = new Random(3);
        double lp = 0, hp = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / (double)Sr;
            double e = (1.0 - Math.Exp(-t * 8.0)) * Math.Exp(-t * 2.4);
            double ns = rng.NextDouble() * 2 - 1;
            lp += 0.06 * (ns - lp);
            hp += 0.02 * (lp - hp);
            Mix(L, R, i, (lp - hp) * e, -0.15 + 0.4 * Math.Min(t, 1.0), 0.07);
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
                short sl = (short)Clamp(Math.Tanh(L[i] * norm) * 32767.0, -32767, 32767);
                short sr = (short)Clamp(Math.Tanh(R[i] * norm) * 32767.0, -32767, 32767);
                bw.Write(sl);
                bw.Write(sr);
            }
        }
    }

    public static void Generate(string path)
    {
        int n = (int)(2.45 * Sr);
        var L = new double[n];
        var R = new double[n];

        Unfold(L, R, n);

        // Bud
        Pad(L, R, 0.00, 60, 1.6, 0.85, -0.12);
        Pad(L, R, 0.00, 64, 1.6, 0.80, 0.10);
        Pad(L, R, 0.00, 67, 1.8, 0.75, 0.00);

        // Petals open, one by one
        Petal(L, R, 0.06, 72, 0.72, -0.35);
        Petal(L, R, 0.16, 76, 0.76, -0.18);
        Petal(L, R, 0.26, 79, 0.82, 0.02);
        Petal(L, R, 0.37, 84, 0.88, 0.22);
        Petal(L, R, 0.49, 88, 0.84, 0.38);
        Petal(L, R, 0.62, 91, 0.70, 0.12);

        Sparkle(L, R, 0.38, 96, 0.55, -0.42);
        Sparkle(L, R, 0.52, 100, 0.48, 0.45);
        Sparkle(L, R, 0.66, 103, 0.40, 0.08);

        // Bloom chord
        Pad(L, R, 0.55, 72, 1.5, 0.90, -0.16);
        Pad(L, R, 0.55, 76, 1.5, 0.88, 0.00);
        Pad(L, R, 0.55, 79, 1.55, 0.86, 0.16);
        Pad(L, R, 0.55, 84, 1.6, 0.70, 0.04);

        // Little victory tag
        Petal(L, R, 0.92, 79, 0.70, -0.12);
        Petal(L, R, 1.08, 84, 0.78, 0.08);
        Petal(L, R, 1.28, 88, 0.86, 0.18);
        Petal(L, R, 1.52, 96, 0.80, 0.00);
        Sparkle(L, R, 1.54, 108, 0.42, 0.30);

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }
}

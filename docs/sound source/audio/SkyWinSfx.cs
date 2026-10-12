using System;
using System.IO;

/// <summary>
/// Sky-mode minesweeper win sting: clouds part, a chime lifts, then a sun sparkle.
/// </summary>
public static class SkyWinSfx
{
    const int Sr = 44100;
    const double TwoPi = Math.PI * 2.0;
    static readonly Random Rng = new Random(15);

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
        int n = (int)(1.45 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 2.7) * (1.0 - Math.Exp(-t * 85.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.34 * Math.Sin(ph * 2.004) * Math.Exp(-t * 6.2)
                + 0.11 * Math.Sin(ph * 2.81) * Math.Exp(-t * 10.5)
                + 0.05 * Math.Sin(ph * 4.07) * Math.Exp(-t * 13.0);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.20);
        }
    }

    static void Sparkle(double[] L, double[] R, double tSec, double midi, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.75 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 5.6) * (1.0 - Math.Exp(-t * 70));
            double s = Math.Sin(TwoPi * f * t) + 0.42 * Math.Sin(TwoPi * f * 2.012 * t) * Math.Exp(-t * 8);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.095);
        }
    }

    static void Pad(double[] L, double[] R, double tSec, double midi, double dur, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((dur + 0.6) * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double a = t < 0.24 ? t / 0.24 : 1.0;
            double r = t > dur ? 1.0 - (t - dur) / 0.6 : 1.0;
            if (r < 0) r = 0;
            Mix(L, R, i0 + k, Math.Sin(TwoPi * f * t) * a * r, pan, vel * 0.046);
        }
    }

    static void Gust(double[] L, double[] R, int n)
    {
        double lpL = 0, lpR = 0, hpL = 0, hpR = 0;
        for (int i = 0; i < n; i++)
        {
            double t = i / (double)Sr;
            double att = 1.0 - Math.Exp(-t * 7.0);
            double fade = t < 0.55 ? 1.0 : Math.Exp(-(t - 0.55) * 2.1);
            double env = att * fade;
            double open = 0.03 + 0.07 * env;
            double nL = Rng.NextDouble() * 2 - 1;
            double nR = Rng.NextDouble() * 2 - 1;
            lpL += open * (nL - lpL);
            lpR += open * (nR - lpR);
            hpL += 0.016 * (lpL - hpL);
            hpR += 0.016 * (lpR - hpR);
            double pan = -0.4 + 0.85 * Math.Min(t * 0.85, 1);
            Mix(L, R, i, (lpL - hpL) * env, pan, 0.09);
            Mix(L, R, i, (lpR - hpR) * env, pan * 0.6, 0.08);
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

        Gust(L, R, n);

        // Open sky pad, C major — same world as sky BGM
        Pad(L, R, 0.00, 48, 1.7, 0.78, -0.12);
        Pad(L, R, 0.00, 55, 1.8, 0.76, 0.12);
        Pad(L, R, 0.00, 60, 1.9, 0.72, 0.00);

        // Lift into the air: C E G C E G
        Bell(L, R, 0.10, 72, 0.70, -0.30);
        Bell(L, R, 0.24, 76, 0.74, -0.14);
        Bell(L, R, 0.38, 79, 0.80, 0.04);
        Bell(L, R, 0.52, 84, 0.88, 0.20);
        Bell(L, R, 0.66, 88, 0.84, 0.34);
        Bell(L, R, 0.80, 91, 0.72, 0.08);

        Sparkle(L, R, 0.40, 96, 0.50, -0.44);
        Sparkle(L, R, 0.58, 100, 0.46, 0.46);
        Sparkle(L, R, 0.76, 103, 0.40, 0.10);

        // Sun breaks through
        Pad(L, R, 0.88, 72, 1.4, 0.90, -0.14);
        Pad(L, R, 0.88, 76, 1.45, 0.88, 0.00);
        Pad(L, R, 0.88, 79, 1.50, 0.86, 0.16);
        Pad(L, R, 0.88, 84, 1.55, 0.72, 0.04);

        Sparkle(L, R, 0.92, 108, 0.55, 0.00);
        Sparkle(L, R, 1.02, 112, 0.38, 0.28);

        // Victory tag riding the wind
        Bell(L, R, 1.18, 79, 0.70, -0.12);
        Bell(L, R, 1.34, 84, 0.78, 0.10);
        Bell(L, R, 1.54, 96, 0.90, 0.02);
        Sparkle(L, R, 1.56, 108, 0.44, 0.22);

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }
}

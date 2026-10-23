using System;
using System.IO;

/// <summary>
/// Shared minesweeper fail sting for forest / ocean / sky modes.
/// Soft Nintendo "aww": a paper puff plus a descending chime.
/// </summary>
public static class MinesweeperFailSfx
{
    const int Sr = 44100;
    const double TwoPi = Math.PI * 2.0;
    static readonly Random Rng = new Random(9);

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

    static void Bell(double[] L, double[] R, double tSec, double midi, double vel, double pan, double decay)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(1.1 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * decay) * (1.0 - Math.Exp(-t * 70.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.22 * Math.Sin(ph * 2.003) * Math.Exp(-t * 7.5)
                + 0.06 * Math.Sin(ph * 2.78) * Math.Exp(-t * 12.0);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.20);
        }
    }

    static void Puff(double[] L, double[] R, double tSec, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.22 * Sr);
        double lp = 0, hp = 0;
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = (1.0 - Math.Exp(-t * 28)) * Math.Exp(-t * 11);
            double ns = Rng.NextDouble() * 2 - 1;
            lp += 0.10 * (ns - lp);
            hp += 0.03 * (lp - hp);
            Mix(L, R, i0 + k, (lp - hp) * e, pan, amp);
        }
    }

    static void Pad(double[] L, double[] R, double tSec, double midi, double dur, double vel, double pan)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((dur + 0.4) * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double a = t < 0.06 ? t / 0.06 : 1.0;
            double r = t > dur ? 1.0 - (t - dur) / 0.4 : 1.0;
            if (r < 0) r = 0;
            Mix(L, R, i0 + k, Math.Sin(TwoPi * f * t) * a * r, pan, vel * 0.04);
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
        double norm = 0.93 / peak;
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
                short sl = (short)Clamp(L[i] * norm * 32767.0, -32767, 32767);
                short sr = (short)Clamp(R[i] * norm * 32767.0, -32767, 32767);
                bw.Write(sl);
                bw.Write(sr);
            }
        }
    }

    public static void Generate(string path)
    {
        int n = (int)(1.70 * Sr);
        var L = new double[n];
        var R = new double[n];

        DryCrumble(L, R, 0.00, 0.55, 0.32);
        WiltTone(L, R, 0.06, 265, 82, 1.15, -0.08, 0.52);
        WiltTone(L, R, 0.18, 198, 64, 1.20, 0.12, 0.34);
        SickDrone(L, R, 0.10, 1.40, 0.22);
        DrySnap(L, R, 0.28, -0.22, 0.28);
        DrySnap(L, R, 0.52, 0.18, 0.24);
        DrySnap(L, R, 0.86, 0.04, 0.18);
        DryCrumble(L, R, 0.70, 0.80, 0.18);

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }

    static void DryCrumble(double[] L, double[] R, double tSec, double dur, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(dur * Sr);
        double lp = 0, hp = 0;
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double u = k / (double)Math.Max(n - 1, 1);
            double e = (1.0 - Math.Exp(-t * 10)) * Math.Exp(-t * 2.1);
            // Darker as it dries
            double open = 0.08 - 0.05 * u;
            double ns = Rng.NextDouble() * 2 - 1;
            lp += open * (ns - lp);
            hp += 0.018 * (lp - hp);
            double flake = ((Rng.NextDouble() < 0.035) ? (Rng.NextDouble() * 2 - 1) : 0) * e;
            Mix(L, R, i0 + k, (lp - hp) * e, -0.2 + 0.4 * u, amp);
            Mix(L, R, i0 + k, flake, 0.15 * Math.Sin(t * 9), amp * 0.7);
        }
    }

    static void WiltTone(double[] L, double[] R, double tSec, double f0, double f1, double dur, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)((dur + 0.15) * Sr);
        double lp = 0;
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double u = k / (double)Math.Max(n - 1, 1);
            double t = k / (double)Sr;
            double f = f0 * Math.Pow(f1 / f0, Math.Pow(Math.Min(u, 1), 0.7));
            double e = (1.0 - Math.Exp(-t * 11)) * Math.Exp(-t * 1.45);
            if (t > dur) e *= Math.Exp(-(t - dur) * 6);
            double s = Math.Sin(TwoPi * f * t) + 0.18 * Math.Sin(TwoPi * f * 1.99 * t);
            lp += 0.20 * (s - lp);
            Mix(L, R, i0 + k, lp * e, pan, amp);
        }
    }

    static void SickDrone(double[] L, double[] R, double tSec, double dur, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(dur * Sr);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = (1.0 - Math.Exp(-t * 3.5)) * Math.Exp(-t * 1.15);
            double s = Math.Sin(TwoPi * 73 * t) + 0.35 * Math.Sin(TwoPi * 77.5 * t);
            Mix(L, R, i0 + k, s * e, -0.06, amp);
        }
    }

    static void DrySnap(double[] L, double[] R, double tSec, double pan, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.09 * Sr);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * 38) * (1.0 - Math.Exp(-t * 80));
            double s = Math.Sin(TwoPi * 210 * t) + 0.4 * (Rng.NextDouble() * 2 - 1) * Math.Exp(-t * 50);
            Mix(L, R, i0 + k, s * e, pan, amp);
        }
    }
}

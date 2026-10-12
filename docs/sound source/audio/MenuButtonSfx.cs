using System;
using System.IO;

/// <summary>
/// Paper-cut menu UI ticks: select (up) and back (down).
/// </summary>
public static class MenuButtonSfx
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

    static void Bell(double[] L, double[] R, double tSec, double midi, double vel, double pan, double decay)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.32 * Sr);
        double f = MidiHz(midi);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double t = k / (double)Sr;
            double e = Math.Exp(-t * decay) * (1.0 - Math.Exp(-t * 90.0));
            double ph = TwoPi * f * t;
            double s = Math.Sin(ph)
                + 0.28 * Math.Sin(ph * 2.004) * Math.Exp(-t * 8)
                + 0.08 * Math.Sin(ph * 2.76) * Math.Exp(-t * 12);
            Mix(L, R, i0 + k, s * e, pan, vel * 0.28);
        }
    }

    static void Tick(double[] L, double[] R, double tSec, double amp)
    {
        int i0 = (int)Math.Round(tSec * Sr);
        int n = (int)(0.012 * Sr);
        var rng = new Random(5);
        for (int k = 0; k < n && i0 + k < L.Length; k++)
        {
            double u = k / (double)Math.Max(n - 1, 1);
            double e = (1.0 - u) * (1.0 - Math.Exp(-u * 50));
            Mix(L, R, i0 + k, (rng.NextDouble() * 2 - 1) * e, 0.0, amp);
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
        double norm = 0.90 / peak;
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

    public static void GenerateSelect(string path)
    {
        int n = (int)(0.22 * Sr);
        var L = new double[n];
        var R = new double[n];
        Tick(L, R, 0.000, 0.10);
        Bell(L, R, 0.000, 76, 0.72, -0.08, 14);
        Bell(L, R, 0.045, 84, 0.86, 0.10, 12);
        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }

    public static void GenerateBack(string path)
    {
        int n = (int)(0.24 * Sr);
        var L = new double[n];
        var R = new double[n];
        Tick(L, R, 0.000, 0.08);
        Bell(L, R, 0.000, 79, 0.70, 0.08, 13);
        Bell(L, R, 0.055, 72, 0.78, -0.06, 10);
        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }
}

using System;
using System.IO;

/// <summary>
/// Short wind-gust SFX for sky-mode minesweeper cell click.
/// </summary>
public static class SkyWindSfx
{
    const int Sr = 44100;
    const double TwoPi = Math.PI * 2.0;

    static double Clamp(double x, double lo, double hi)
    {
        return x < lo ? lo : (x > hi ? hi : x);
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

    public static void Generate(string path)
    {
        var rng = new Random(20260915);
        int n = (int)(2.15 * Sr);
        var L = new double[n];
        var R = new double[n];
        double lpL = 0, lpR = 0, hpL = 0, hpR = 0, whistle = 0;
        double phase = 0;

        for (int i = 0; i < n; i++)
        {
            double t = i / (double)Sr;
            double att = 1.0 - Math.Exp(-t * 5.2);
            double fadeStart = 0.62;
            double fadeLen = 1.53;
            double hold = 1.0;
            if (t > fadeStart)
            {
                double x = (t - fadeStart) / fadeLen;
                if (x < 0) x = 0;
                if (x > 1) x = 1;
                hold = 1.0 - x * x * (3 - 2 * x);
                hold = hold * hold * hold;
            }
            double env = att * hold;

            double open = 0.026 + 0.068 * att * hold;
            double nL = rng.NextDouble() * 2 - 1;
            double nR = rng.NextDouble() * 2 - 1;
            lpL += open * (nL - lpL);
            lpR += open * (nR - lpR);
            hpL += 0.016 * (lpL - hpL);
            hpR += 0.016 * (lpR - hpR);
            double airL = lpL - hpL;
            double airR = lpR - hpR;

            double spinRate = 7.0 * Math.Exp(-t * 1.15) + 1.8;
            phase += spinRate / Sr;
            double pan = 0.58 * Math.Sin(phase);
            double pl = Math.Cos((pan + 1.0) * Math.PI * 0.25);
            double pr = Math.Sin((pan + 1.0) * Math.PI * 0.25);

            L[i] += airL * env * pl * 0.92;
            R[i] += airR * env * pr * 0.92;
            L[i] += airR * env * pr * 0.20;
            R[i] += airL * env * pl * 0.20;

            double wHz = 1320 + 160 * Math.Sin(phase * 0.5);
            whistle += 0.22 * (rng.NextDouble() * 2 - 1 - whistle);
            double w = Math.Sin(TwoPi * wHz * t) * whistle * env * 0.035;
            L[i] += w * pl;
            R[i] += w * pr;
        }

        WriteWav(path, L, R);
        Console.WriteLine("Wrote " + path);
    }
}

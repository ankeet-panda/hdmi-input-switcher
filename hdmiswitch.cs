using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;

// hdmiswitch: set monitor input over DDC/CI (VCP 0x60). Native, no PowerShell, no dependencies.
static class P {
    delegate bool EnumProc(IntPtr h, IntPtr dc, IntPtr r, IntPtr d);
    [StructLayout(LayoutKind.Sequential, Pack = 1, CharSet = CharSet.Unicode)]
    struct PM { public IntPtr h; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string d; }
    [DllImport("user32.dll")] static extern bool EnumDisplayMonitors(IntPtr dc, IntPtr r, EnumProc p, IntPtr d);
    [DllImport("dxva2.dll")] static extern bool GetNumberOfPhysicalMonitorsFromHMONITOR(IntPtr m, out uint n);
    [DllImport("dxva2.dll")] static extern bool GetPhysicalMonitorsFromHMONITOR(IntPtr m, uint n, [Out] PM[] a);
    [DllImport("dxva2.dll")] static extern bool DestroyPhysicalMonitors(uint n, PM[] a);
    [DllImport("dxva2.dll")] static extern bool GetVCPFeatureAndVCPFeatureReply(IntPtr h, byte c, IntPtr t, out uint cur, out uint max);
    [DllImport("dxva2.dll")] static extern bool SetVCPFeature(IntPtr h, byte c, uint v);
    [DllImport("user32.dll")] static extern int GetDisplayConfigBufferSizes(uint f, out uint p, out uint m);
    [DllImport("user32.dll")] static extern int QueryDisplayConfig(uint f, ref uint p, byte[] pi, ref uint m, byte[] mi, IntPtr t);
    [DllImport("user32.dll")] static extern int SetDisplayConfig(uint p, IntPtr pi, uint m, IntPtr mi, uint f);

    const uint SDC_APPLY = 0x80, SDC_INTERNAL = 0x1, SDC_CLONE = 0x2, SDC_EXTEND = 0x4;

    static bool IsClone() {
        uint p, m;
        if (GetDisplayConfigBufferSizes(2, out p, out m) != 0 || p < 2) return false;
        byte[] pi = new byte[72 * p], mi = new byte[64 * m];
        if (QueryDisplayConfig(2, ref p, pi, ref m, mi, IntPtr.Zero) != 0) return false;
        var s = new HashSet<uint>();
        for (int i = 0; i < p; i++) s.Add(BitConverter.ToUInt32(pi, 72 * i + 8));
        return s.Count < p;
    }

    // Sets the input on every physical monitor that answers DDC/CI; returns how many accepted.
    static int Apply(uint val) {
        int ok = 0;
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (hm, dc, r, d) => {
            uint n;
            if (!GetNumberOfPhysicalMonitorsFromHMONITOR(hm, out n) || n == 0) return true;
            var a = new PM[n];
            if (!GetPhysicalMonitorsFromHMONITOR(hm, n, a)) return true;
            foreach (var pm in a) {
                if (SetVCPFeature(pm.h, 0x60, val)) ok++;   // write only: a read-back would double the latency
            }
            DestroyPhysicalMonitors(n, a);
            return true;
        }, IntPtr.Zero);
        return ok;
    }

    static uint Parse(string s) {
        switch (s.ToUpperInvariant()) {
            case "VGA1": return 1; case "VGA2": return 2; case "DVI1": return 3; case "DVI2": return 4;
            case "DP1": return 0x0F; case "DP2": return 0x10; case "HDMI1": return 0x11; case "HDMI2": return 0x12;
        }
        return Convert.ToUInt32(s.StartsWith("0x", StringComparison.OrdinalIgnoreCase) ? s.Substring(2) : s, 16);
    }

    static int Main(string[] args) {
        if (args.Length < 1) { Console.WriteLine("usage: hdmiswitch HDMI1|HDMI2|DP1|DP2|DVI1|DVI2|VGA1|VGA2|0x11"); return 2; }
        uint val = Parse(args[0]);
        int n = 0;
        for (int i = 0; i < 3 && n == 0; i++) { if (i > 0) Thread.Sleep(150); n = Apply(val); }   // fast path: no display-mode change; DDC is occasionally busy
        bool fallback = false;
        if (n == 0) {
            // Monitor invisible to Windows (Duplicate hides it; "PC screen only" disables it): extend, retry, restore.
            fallback = true;
            bool clone = IsClone();
            SetDisplayConfig(0, IntPtr.Zero, 0, IntPtr.Zero, SDC_APPLY | SDC_EXTEND);
            for (int i = 0; i < 20 && n == 0; i++) { Thread.Sleep(250); n = Apply(val); }
            Thread.Sleep(300);
            SetDisplayConfig(0, IntPtr.Zero, 0, IntPtr.Zero, SDC_APPLY | (clone ? SDC_CLONE : SDC_INTERNAL));
        }
        string msg = DateTime.Now.ToString("s") + "  " + args[0] + "  " + (n > 0 ? "ok" : "no DDC/CI monitor responded") + (fallback ? " (extend fallback used)" : "");
        Console.WriteLine(msg);
        try { System.IO.File.WriteAllText(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "last-run.log"), msg); } catch { }
        return n > 0 ? 0 : 1;
    }
}

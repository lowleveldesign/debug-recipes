<%@ Page Language="C#" AutoEventWireup="true" Trace="true" TraceMode="SortByCategory" %>

<%@ Import Namespace="System.Runtime.InteropServices" %>
<%@ Import Namespace="System.Threading" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="Microsoft.Win32" %>
<%@ Import Namespace="System.Diagnostics" %>
<%@ Import Namespace="System.Reflection" %>

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>ASP.NET Diagnostic Page</title>


    <style type="text/css">
        .error {
            font-weight: bold;
            color: Red;
        }

        .box {
            border-width: thin;
            border-style: solid;
            padding: .2em 1em .2em 1em;
            background-color: #dddddd;
        }

        .errorInset {
            padding: 1em;
            background-color: #ffbbbb;
        }

        body {
            font-family: Calibri, Helvetica;
            padding: 0;
            margin: 1em;
        }
    </style>

    <script runat="server">
        private static Process process = Process.GetCurrentProcess();

        // Checking the version using >= will enable forward compatibility,
        // however you should always compile your code on newer versions of
        // the framework to ensure your app works the same.
        private static string CheckFor45DotVersion(int releaseKey)
        {
            if (releaseKey >= 393273) {
                return "4.6 RC or later";
            }
            if ((releaseKey >= 379893)) {
                return "4.5.2 or later";
            }
            if ((releaseKey >= 378675)) {
                return "4.5.1 or later";
            }
            if ((releaseKey >= 378389)) {
                return "4.5 or later";
            }
            // This line should never execute. A non-null release key should mean
            // that 4.5 or later is installed.
            return "No 4.5 or later version detected";
        }


        private static string IsAppDomainHomogenous(AppDomain appDomain)
        {
            // AppDomain.IsHomogenous didn't exist prior to .NET 4, so use Reflection to look it up
            PropertyInfo pInfo = typeof(AppDomain).GetProperty("IsHomogenous");
            if (pInfo == null) {
                return "unknown";
            }

            // MethodInfo.Invoke demands ReflectionPermission when the target is AppDomain, but since target method is transparent we can instantiate a Delegate instead
            return Convert.ToString(((Func<bool>)Delegate.CreateDelegate(typeof(Func<bool>), appDomain, pInfo.GetGetMethod()))());
        }

        private static string IsAssemblyFullTrust(Assembly assembly)
        {
            // Assembly.IsFullyTrusted didn't exist prior to .NET 4, so use Reflection to look it up
            PropertyInfo pInfo = typeof(Assembly).GetProperty("IsFullyTrusted");
            if (pInfo == null) {
                return "unknown";
            }

            // MethodInfo.Invoke demands ReflectionPermission when the target is Assembly, but since target method is transparent we can instantiate a Delegate instead
            return Convert.ToString(((Func<bool>)Delegate.CreateDelegate(typeof(Func<bool>), assembly, pInfo.GetGetMethod()))());
        }
    </script>
</head>
<body>
    <form id="form1" runat="server">


        <h2>Environment Information</h2>
        <div class="box">
            <p>
                <b>Operating system:</b> <%= Environment.OSVersion %><br />
                <b>.NET Framework version:</b> <%= Environment.Version %> (<%= IntPtr.Size * 8 %>-bit)<br />
                <b>Web server:</b> <%= HttpContext.Current.Request.ServerVariables["SERVER_SOFTWARE"] ?? "N/A" %><br />
                <b>Integrated pipeline:</b> <%= HttpRuntime.UsingIntegratedPipeline %><br />
                <b>Worker process:</b> <%= process.ProcessName %> (PID: <%= process.Id %>, Session: <%= process.SessionId %>)<br />
                <b>AppDomain:</b> Homogenous = <%= IsAppDomainHomogenous(AppDomain.CurrentDomain) %>, FullTrust = <%= IsAssemblyFullTrust(GetType().Assembly) %><br />
                <b>Request.ApplicationPath:</b> = <%= Request.ApplicationPath %><br />
                <b>Request.PhysicalApplicationPath</b> = <%= Request.PhysicalApplicationPath %><br />
                <b>Request.PhysicalPath</b> = <%= Request.PhysicalPath %><br />
                <b>Request.UrlReferrer</b> = <%= Request.UrlReferrer %><br />
                <b>Request.UserLanguages</b> = <%= string.Join(",", (Request.UserLanguages ?? new string[0])) %><br />
                <b>Server</b> = <%= Environment.MachineName %><br />
                <b>Thread identity</b> = <%= Thread.CurrentPrincipal != null ? Thread.CurrentPrincipal.Identity.Name : "N/A" %><br />
            </p>
        </div>

        <h2>Installed .NET versions</h2>
        <div class="box">
            <p>
                <%
                    try {
                        RegistryKey installed_versions = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\NET Framework Setup\NDP");
                        string[] version_names = installed_versions.GetSubKeyNames();
                        //version names start with 'v', eg, 'v3.5' which needs to be trimmed off before conversion
                        //double Framework = Convert.ToDouble(version_names[version_names.Length - 1].Remove(0, 1), CultureInfo.InvariantCulture);
                        for (int i = 0; i < version_names.Length; i++) {
                            String framework = version_names[i];
                            int SP = Convert.ToInt32(installed_versions.OpenSubKey(version_names[i]).GetValue("SP", 0));
                            Response.Write(framework + (SP != 0 ? " SP" + SP : "") + "<br />");
                        }

                        using (RegistryKey ndpKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32).OpenSubKey("SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full\\")) {
                            int releaseKey = Convert.ToInt32(ndpKey.GetValue("Release"));
                            if (true) {
                                Response.Write("v" + CheckFor45DotVersion(releaseKey) + "<br />");
                            }
                        }
                    } catch (Exception ex) {
                        Response.Write("Not available");
                    }
                %>
            </p>
        </div>
        <h2>Environment Variables</h2>
        <div class="box">
            <p>
                <%
                    var variables = Environment.GetEnvironmentVariables();
                    foreach (DictionaryEntry entry in variables) {
                        Response.Write("<b>" + entry.Key.ToString() + "</b> = ");
                        Response.Write(entry.Value);
                        Response.Write("<br />");
                    }
                %>
            </p>
        </div>

    </form>
</body>
</html>

<%@ Page Language="C#" AutoEventWireup="true" Trace="true" TraceMode="SortByCategory" %>
<%@ Import namespace="System.Runtime.InteropServices" %>
<%@ Import namespace="System.Threading" %>
<%@ Import namespace="System.Globalization" %>
<%@ Import namespace="Microsoft.Win32" %>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>ASP.NET Diagnostic Page</title>

<script runat="server">
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
</script>
</head>
<body>
    <form id="form1" runat="server">

    <h2>Environment</h2>
    <pre>
Request.ApplicationPath             = <%= Request.ApplicationPath %>
Request.PhysicalApplicationPath     = <%= Request.PhysicalApplicationPath %>
Request.PhysicalPath                = <%= Request.PhysicalPath %>
Request.UrlReferrer                 = <%= Request.UrlReferrer %>
Request.UserLanguages               = <%= string.Join(",", (Request.UserLanguages ?? new string[0])) %>

Server                              = <%= Environment.MachineName %>
.NET version                        = <%= RuntimeEnvironment.GetSystemVersion() %>

Thread identity                     = <%= Thread.CurrentPrincipal != null ? Thread.CurrentPrincipal.Identity.Name : "N/A" %>
    </pre>

    <h2>Installed .NET versions</h2>
<pre>
<%
try {
    RegistryKey installed_versions = Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Microsoft\NET Framework Setup\NDP");
    string[] version_names = installed_versions.GetSubKeyNames();
    //version names start with 'v', eg, 'v3.5' which needs to be trimmed off before conversion
    //double Framework = Convert.ToDouble(version_names[version_names.Length - 1].Remove(0, 1), CultureInfo.InvariantCulture);
    for (int i = 0; i < version_names.Length; i++) {
        String framework = version_names[i];
        int SP = Convert.ToInt32(installed_versions.OpenSubKey(version_names[i]).GetValue("SP", 0));
        Response.Write(framework + (SP != 0 ? " SP" + SP : "") + Environment.NewLine);
    }

    using (RegistryKey ndpKey = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry32).OpenSubKey("SOFTWARE\\Microsoft\\NET Framework Setup\\NDP\\v4\\Full\\")) {
        int releaseKey = Convert.ToInt32(ndpKey.GetValue("Release"));
        if (true) {
            Response.Write("v" + CheckFor45DotVersion(releaseKey));
        }
    }
} catch (Exception ex) {
    Response.Write("Not available");
}
%>
</pre>
    <h2>Environment Variables</h2>
    <pre>
<%
        var variables = Environment.GetEnvironmentVariables();
        foreach (DictionaryEntry entry in variables)
        {
            Response.Write(entry.Key.ToString().PadRight(30));
            Response.Write(entry.Value);
            Response.Write(Environment.NewLine);
        }
    %>
    </table>
    </pre>

    </form>
</body>
</html>

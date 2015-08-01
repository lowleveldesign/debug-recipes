<%@ Page Language="C#" %>
<script runat="server">

 protected void dumpObject(object o, Table outputTable)
    {

    try
	{
        Type refl_WindowsIdenty = typeof(System.Security.Principal.WindowsIdentity);

        System.Reflection.MemberInfo[] refl_WindowsIdenty_members = o.GetType().FindMembers(
                System.Reflection.MemberTypes.Property,
                System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance,
                delegate(System.Reflection.MemberInfo objMemberInfo, Object objSearch) { return true; },
                null);

        foreach (System.Reflection.MemberInfo currentMemberInfo in refl_WindowsIdenty_members)
        {
            TableRow r = new TableRow();
            TableCell k = new TableCell();
            TableCell v = new TableCell();
            System.Reflection.MethodInfo getAccessorInfo = ((System.Reflection.PropertyInfo)currentMemberInfo).GetGetMethod();

            k.Text = currentMemberInfo.Name;
            object value = getAccessorInfo.Invoke(o, null);
            if (typeof(IEnumerable).IsInstanceOfType(value) && !typeof(string).IsInstanceOfType(value))
            {
                foreach (object item in (IEnumerable)value)
                {
                    v.Text += item.ToString() + "<br />";
                }
            }
            else
            {
                v.Text = value.ToString();
            }

            r.Cells.AddRange(new TableCell[] { k, v });
            outputTable.Rows.Add(r);
        }
	}
    catch
	 {}

    }

protected void Page_Load(object sender, EventArgs e)
    {

    AuthMethod.Text = "Anonymous";
    AuthUser.Text = "none";


   //***** Authentication header type (Basic, Negotiate...etc)

   string AUTH_TYPE=Request.ServerVariables["AUTH_TYPE"];
   if (AUTH_TYPE.Length>0) AuthMethod.Text = AUTH_TYPE;

   //***** Authenticated user
   string AUTH_USER=Request.ServerVariables["AUTH_USER"];
   if (AUTH_USER.Length>0) AuthUser.Text  = AUTH_USER;

   //***** If NEGOTIATE is used, assume KERBEROS is length of auth. header exceeds 1000 bytes

   if (AuthMethod.Text == "Negotiate")
	{
	string auth=Request.ServerVariables.Get("HTTP_AUTHORIZATION");
	if ((auth!=null)&&(auth.Length > 1000))
			AuthMethod.Text = AuthMethod.Text + " (KERBEROS)";
		else
			AuthMethod.Text = AuthMethod.Text + " (NTLM)" ;
	}


	ThreadId.Text=System.Security.Principal.WindowsIdentity.GetCurrent().Name;

        //set the process identity in the corresponding label
        dumpObject(System.Security.Principal.WindowsIdentity.GetCurrent(), tblProcessIdentity);

        //set the thread identity in the corresponding lable
        dumpObject(System.Threading.Thread.CurrentPrincipal.Identity, tblThreadIdentity);

	int loop1, loop2;
	NameValueCollection coll;

	// Load ServerVariable collection into NameValueCollection object.
	coll=Request.ServerVariables;
	// Get names of all keys into a string array.
	String[] arr1 = coll.AllKeys;
	for (loop1 = 0; loop1 < arr1.Length; loop1++)
		{
		TableRow r = new TableRow();
	        TableCell k = new TableCell();
                TableCell v = new TableCell();
		k.Text=arr1[loop1];
  	   	String[] arr2=coll.GetValues(arr1[loop1]);

		for (loop2 = 0; loop2 < arr2.Length; loop2++) {
		      v.Text=v.Text+Server.HtmlEncode(arr2[loop2]);
		   }


  		v.Text=Server.HtmlEncode(arr2[0]);
		r.Cells.AddRange(new TableCell[] { k, v });
		tblSrvVar.Rows.Add(r);
		}


	/*
	IEnumerator en = Request.ServerVariables.Keys.GetEnumerator();
	en.MoveNext();

	foreach (string key in Request.ServerVariables.Keys)
	{
		TableRow r = new TableRow();
	        TableCell k = new TableCell();
                TableCell v = new TableCell();
		k.Text = key;
		v.Text=Request.ServerVariables[key];
		r.Cells.AddRange(new TableCell[] { k, v });
		tblSrvVar.Rows.Add(r);
	}*/


    }

</script>

<html>
<body>
<font face="Verdana">
<center><H2>WHO Page</H2><br>
</center>
<table border=1>
<tr><td>Authentication Method </td><td><b><asp:label id=AuthMethod runat=server/></b></td><td>Request.ServerVariables("AUTH_TYPE")</td></tr>
<tr><td>Identity </td><td><b><asp:label id=AuthUser runat=server /></b></td><td>Request.ServerVariables("AUTH_USER") or System.Threading.Thread.CurrentPrincipal.Identity</td></tr>
<tr><td>Windows identity </td><td> <b><asp:label id=ThreadId runat=server /></b></td><td>System.Security.Principal.WindowsIdentity.Getcurrent</td></tr>
</table>

<fieldset>
            <label>Identity (System.Threading.Thread.CurrentPrincipal.Identity)</label>
            <asp:Table ID="tblThreadIdentity" runat="server"></asp:Table>
        </fieldset>


	<fieldset>
            <label>Windows Identity (System.Security.Principal.WindowsIdentity.GetCurrent)</label>
            <asp:Table ID="tblProcessIdentity" runat="server"></asp:Table>
        </fieldset>

Dump of server variables :
<br><br>
<asp:Table ID="tblSrvVar" runat="server"></asp:Table>

</font>
</body>
</html>


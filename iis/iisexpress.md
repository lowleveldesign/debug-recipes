
IIS7 Express
============

IIS Express runs as a SINGLE process and it's NOT POSSIBLE to host multiple virtual application with different .NET versions under the same site (only one .NET version will be loaded).

Configuration
-------------

### Global variables in IIS Express ###

- `%IIS_BIN%` - referes to IIS Express folder of the currently executing IIS express instance
- `%IIS_USER_HOME%` - %userprofile%\documents\iisexpress\
- `%IIS_SITES_HOME%` - %userprofile%\documents\my web sites

### Run iisexpress on reserver port (lower than 1024) ###

Allow any user to run iisexpress on the 80 port:

    netsh http add urlacl url=http://localhost:80/ user=everyone

Add binding configuration:

    <binding protocol="http" bindingInformation="*:80:localhost"/>

To remove the configuration run:

    netsh http delete urlacl url=http://localhost:80/

### Enable SSH (https) on an endpoint ###

Based on <http://www.hanselman.com/blog/WorkingWithSSLAtDevelopmentTimeIsEasierWithIISExpress.aspx>

You may use the self-signed IIS Express certificate, you may find it using:

    certmgr.exe /c /s /r localMachine MY

By default IIS Express registers bindings for all the ports starting from 44301 till 44399 with its certificate. You may list them using:

    netsh http show sslcert

or create a new certificate, eg.:

    makecert -r -pe -n "CN=HANSELMAN-W500" -b 01/01/2000 -e 01/01/2036 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12

Then you need to get its SHA1 hash (thumbprint) and register it in http.sys (if in powershell remember about escaping {}):

    netsh http add sslcert ipport=0.0.0.0:443 appid={214124cd-d05b-4309-9af9-9caa44b2b74a} certhash=YOURCERTHASHHERE

To delete registration use `netsh http delete sslcert ipport=YOURIPPORT`.

If you would like to run the iisexpress on non-privileged account you may also add an urlacl:

    netsh http add urlacl url=https://localhost:443/ user=everyone

Finally you can add binding for your site to the applicationHost.config, eg.:

    <site name="MvcApplication18" id="39">
      <application path="/" applicationPool="Clr4IntegratedAppPool">
         <virtualDirectory path="/" physicalPath="c:\users\scottha\documents\visual studio 2010\Projects\MvcApplication18\MvcApplication18" />
      </application>
      <bindings>
        <binding protocol="http" bindingInformation="*:15408:localhost" />
        <binding protocol="https" bindingInformation="*:44302:localhost" />
        <binding protocol="http" bindingInformation="*:80:hanselman-w500" />
        <binding protocol="https" bindingInformation="*:443:hanselman-w500" />
      </bindings>
    </site>

Logging
-------

You can enable tracing by using the **/trace** switch. Following values are accepted: 'none', 'n', 'info', 'i', 'warning', 'w', 'error', and 'e'. W3C logs are stored in the `%IIS_USER_HOME%\Logs` folder and tracing logs can be found in `%IIS_USER_HOME%\TraceLogFiles`.

Syntax
------

    iisexpress [/config:config-file] [/site:site-name] [/siteid:site-id] [/systray:true|false] [/trace:trace-level] [/userhome:user-home-directory]
    iisexpress /path:app-path [/port:port-number] [/clr:clr-version] [/systray:true|false] [/trace:trace-level]

    /config:config-file
    The full path to the applicationhost.config file. The default value is the IISExpress\config\applicationhost.config file that is located in the user's Documents folder.

    /site:site-name
    The name of the site to launch, as described in the applicationhost.config file.

    /siteid:site-id
    The ID of the site to launch, as described in the applicationhost.config file.

    /path:app-path
    The full physical path of the application to run. You cannot combine this option with the /config and related options.

    /port:port-number
    The port to which the application will bind. The default value is 8080. You must also specify the /path option.

    /clr:clr-version
    The .NET Framework version (e.g. v2.0) to use to run the application. The default value is v4.0. You must also specify the /path option.

    /systray:true|false
    Enables or disables the system tray application. The default value is true.

    /userhome:user-home-directory
    IIS Express user custom home directory (default is %userprofile%\documents\iisexpress).

    /trace:trace-level
    Valid values are 'none', 'n', 'info', 'i', 'warning', 'w', 'error', and 'e'. The default value is none.

    \Examples:
    iisexpress /site:WebSite1
    This command runs WebSite1 site from the user profile configuration file.

    iisexpress /config:c:\myconfig\applicationhost.config
    This command runs the first site in the specified configuration file.

    iisexpress /path:c:\myapp\ /port:80
    This command runs the site from the 'c:\myapp' folder over port '80'.

IIS Express links
----------------

- [Working with SSL at Development Time is easier with IISExpress](http://www.hanselman.com/blog/WorkingWithSSLAtDevelopmentTimeIsEasierWithIISExpress.aspx)

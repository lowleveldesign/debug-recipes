from <http://blogs.msdn.com/b/friis/archive/2013/01/14/iis-7-7-5-et-la-g-233-n-233-ration-d-un-log-handle-suite-224-une-erreur-500-provoqu-233-e-par-un-lock-que-personne-ne-semble-d-233-tenir.aspx>

Get settings configured in web.config. Then enable customActions in applicationhost.config:

    appcmd.exe set config -section:system.applicationHost/sites "/[name='NomDeVotreSite'].traceFailedRequestsLogging.customActionsEnabled:"true"" /commit:apphost

In order to run handle you need to set ApplicationPook identity to Local System. You also need to set rights for the Local System account to Load and unload device drivers (gpedit.msc -> Computer Configuration -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignments).

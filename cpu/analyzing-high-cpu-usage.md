
Troubleshooting CPU problems in .NET applications
=================================================

Collecting traces
-----------------

### Using PerfView ###

We can use PerfView to collect traces when CPU usage is higher than 90%:

    perfview collect /merge /zip /AcceptEULA "/StopOnPerfCounter=Processor:% Processor Time:_Total>90" /nogui /NoNGenRundown /DelayAfterTriggerSec=30



Links
-----

- <http://samsaffron.com/archive/2009/11/11/Diagnosing+runaway+CPU+in+a+Net+production+application>
- [.Net contention scenario using PerfView](http://blogs.msdn.com/b/rihamselim/archive/2014/02/25/net-contention-scenario-using-perfview.aspx)


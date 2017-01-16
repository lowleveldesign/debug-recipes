
### Finding most used locations in .etl log ###

Use any of the disks graphs and choose summary table. Then move the **Path Tree** column to the beginning. You should then see access paths with their corresponding **Service Time**. This way we may find which paths were the most occupied and with such information we may investigate further and list suspected processes (for instance if the "busy" path was c:\windows\assembly we may assume that .NET processes generated the overload).

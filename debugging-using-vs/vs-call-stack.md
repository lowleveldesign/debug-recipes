
.NET call stack analysis in VS
==============================

Call stack window
-----------------

### Stopping after function return ###

You can place a breakpoint on a stack frame - just select the frame and press F9:

![vs-call-stack-break](vs-call-stack-break.PNG)

VS will stop when unwinding the stack and you will be able to examine results of the previously called functions (usuall in EAX/RAX register).

### External Code frames in Call Stack ###

Disable Just my Code and they will disappear.

Analyze call stack manually
---------------------------

Look at the sample code below. In subsequent points we will analyze the stack after the Test method was called.

```
private static void Main() {
    Test("aa", "bb", "cc", "dd", "ee");
}

private static void Test(String a, String b, String c, String d, String e) {
    foreach (var s in new[] { a, b, c, d, e }) {
        Console.WriteLine(s);
    }
}
```

What I will show you in next paragraphs is a very basic stack decomposition (for example it does not cover passing floats), but should be sufficient for most diagnosis cases of your .net applications.

### 32bit ###

If we compile the application as a 32bit assembly and step into the Test method the stack might look as follows (we can have this view by dragging EBP registry value in Registers window onto the Memory window):

```
...
0x0626EE24  00000000  ....
0x0626EE28  0626ef1c  .ď&.
0x0626EE2C  0626ee78  xî&.
0x0626EE30  02102663  c&..
0x0626EE34  0216d92c  ,Ů..
0x0626EE38  0216d918  .Ů..
0x0626EE3C  0216d904  .Ů..
0x0626EE40  74534ff0  đOSt
...
```

Our Registers window has the following values:

```
EAX = 006DC6A8 EBX = 0626EF1C ECX = 0216D8DC
EDX = 0216D8F0 ESI = 00000000 EDI = 0626EE90
EIP = 02102683 ESP = 0626EE2C EBP = 0626EE2C
EFL = 00000206
```

CLR calling conventions on 32bit is quite similar to the fastcall convention: two first parameters are passed in ECX and EDX registers,other parameters are pushed to the stack. In our case the decomposition will look as follows:

```
ECX => 0x0216D8DC 21b4 7322 0002 0000  ´!"s....
       0x0216D8E4 0061 0061 0000 0000  a.a.....

EDX => 0x0216D8F0  21b4 7322 0002 0000  ´!"s....
       0x0216D8F8  0062 0062 0000 0000  b.b.....

The Call Stack:

       ...
       0x0626EE24  00000000
       0x0626EE28  0626ef1c
EBP => 0x0626EE2C  0626ee78
       0x0626EE30  02102663
       0x0626EE34  0216d92c => 0x0216D92C  21b4 7322 0002 0000  ´!"s....
                               0x0216D934  0065 0065 0000 0000  e.e.....
       0x0626EE38  0216d918 => 0x0216D918  21b4 7322 0002 0000  ´!"s....
                               0x0216D920  0064 0064 0000 0000  d.d.....
       0x0626EE3C  0216d904 => 0x0216D904  21b4 7322 0002 0000  ´!"s....
                               0x0216D90C  0063 0063 0000 0000  c.c.....
       0x0626EE40  74534ff0
       ...
```

If you prefer visualizations have a look at this diagram:

![vs-stack-decompose](vs-stack-decompose.png)

### 64bit ###

CLR calling convention is very similar to x64 calling conventions. First 4 parameters go to registries: RCX, RDX, R8 and R9. The rest is pushed onto the stack. Unfortunately they are not pushed on the stack directly but there is some fixed shadow space reserved. In our sample with registers:

```
RAX = 00007FF85855C8E8 RBX = 000000293920E7E8 RCX = 000000291F70BE70 RDX = 000000291F70BE90 RSI = 000000293920E778 RDI = 000000293920E910 R8  = 000000291F70BEB0 R9  = 000000291F70BED0 R10 = 00007FF8586C4BC0 R11 = 000000293920E500 R12 = 000000293920E888 R13 = 000000293920E940 R14 = 000000293920E7E8 R15 = 000000293920E710 RIP = 00007FF858673D3C RSP = 000000293920E5A0 RBP = 000000293920E5A0 EFL = 00000206
```

the stack might look as follows:

```
...
       0x000000293920E588  0000000000000000  ........
       0x000000293920E590  0000cefdf5be5b36  6[ľőýÎ..
       0x000000293920E598  00007ff8b8380b30  0.8¸ř...
RBP => 0x000000293920E5A0  000000293920e910  .é 9)...
       0x000000293920E5A8  000000293920e600  .ć 9)...
       0x000000293920E5B0  000000293920e910  .é 9)...
       0x000000293920E5B8  000000293920e778  xç 9)...
       0x000000293920E5C0  000000293920e7e8  čç 9)...
       0x000000293920E5C8  000000293920e600  .ć 9)...
       0x000000293920E5D0  000000293920e888  .č 9)...
       0x000000293920E5D8  000000293920e940  @é 9)...
       0x000000293920E5E0  000000293920e7e8  čç 9)...
       0x000000293920E5E8  000000293920e710  .ç 9)...
       0x000000293920E5F0  000000293920e600  .ć 9)...
       0x000000293920E5F8  00007ff858673c09  .<gXř...
       0x000000293920E600  000000291f70be70  pľp.)...
       0x000000293920E608  000000291f70be90  .ľp.)...
       0x000000293920E610  000000291f70beb0  °ľp.)...
       0x000000293920E618  000000291f70bed0  Đľp.)...
       0x000000293920E620  000000291f70bef0  đľp.)... => 0x000000291F70BEF0  0bd8 b6da 7ff8 0000  Ř.Ú¶ř...
                                                         0x000000291F70BEF8  0002 0000 0065 0065  ....e.e.
       0x000000293920E628  000000293920e710  .ç 9)...
       0x000000293920E630  000000293920e660  `ć 9)...
       0x000000293920E638  00007ff8b7d10453  S.Ń·ř...
       0x000000293920E640  00007ff8b7d878cd  ÍxŘ·ř...
       0x000000293920E648  00007ff800000001  ....ř...
       0x000000293920E650  0000000000000001  ........
...
```

### Inline calls and jumps ###

Those cases are often quite complicated and require analysis of assembly code to find the registry or memory address where our variable value is stored. As a rule of thumb you may examine values of the registers (you should be able to see which memory addresses seem valid and which not) and memory around the EBP/RSP register.

Links
-----

- [x64 Software Conventions](https://msdn.microsoft.com/en-us/library/7kcdt6fy.aspx)


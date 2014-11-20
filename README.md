PrettyBin
=========

Make bin folder of your project small, pretty and easy to maintain!

Moves dll,pdb and xml in bin/lib subfolder and ensures, that everything works.

  Before                            After

app.exe                             /lib

app.config                          app.exe

lib1.dll                            app.config

lib2.dll                            NLog.config

lib3.dll

lib4.dll

lib5.dll

...

where the hell is NLog config

...

xml.xml

...




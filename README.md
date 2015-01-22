PrettyBin
=========

Make bin folder of your project small, pretty and search friendly. 
Can you or your administrators always easily find App.config or exe  among dll and pdb files? If not than PrettyBin is for you!


It moves dll,pdb and xml in bin/lib subfolder using an MSBuild task. Than it modifies App.config to look for dependencies in lib subfolder.


Also PrettyBin gives you a customizable example of how it can be done.

----------------------------------------------
Your bin folder will look like this:

/lib

YourApp.exe

YourApp.config

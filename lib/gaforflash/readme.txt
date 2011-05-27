Google Analytics Tracking For Adobe Flash
=========================================
You can find the latest version of gaforflash on http://code.google.com/p/gaforflash/

Installation for Flash CS3
==========================
Before you begin to use gaforflash to add Analytics tracking within Flash CS3,
you first need to add the gaforflash SWC to Flash CS3.

To do so:
1. If you have Flash CS3 currently open, quit the application.

2. Navigate to the location where you unzipped the Google Analytics zip
   and find the swc (e.g. lib/analytics_flash.swc).

3. Create a "Google" directory in one of the following locations
   and copy the SWC file there:
   - (Windows) C:\Program Files\Adobe\ Adobe Flash CS3\language\Configuration\Components
   - (Mac OS X) Macintosh HD/Applications/Adobe Flash CS3/Configuration/Components

Flash CS3 is now set up to support Google Analytics Tracking For Adobe Flash.

Alternatively if you want to use gaforflash in code-only mode
you can do the same as the above and add the lib/analytics.swc,
you will then need to drag the "AnalyticsLibrary" component in your Library.

Installation for Flex Builder 3
===============================
Before you can compile your code, you will need to link it to the gaforflash SWC file.

To do so:
1. select Project->Properties.
   A Properties dialog box will appear for your project.
   Click on Flex Build Path and then select the Library Path tab:

2. Click Add SWC... within the Library Path pane.
   An Add SWC dialog box will appear.
   Navigate to the location where you unzipped the Google Analytics zip
   and select lib/analytics.swc file and click OK.

or

Just drop the analytics.swc file into your Flex project /libs directory

Documentation
=============
Documentation of the gaforflash code is in the /doc directory.

You can also consult the getting started documentation
http://code.google.com/apis/analytics/docs/flashTrackingIntro.html

and the project wiki for more advanced usage
http://code.google.com/p/gaforflash/wiki/

Problem
=======
Please send any usage questions to http://groups.google.com/group/ga-for-flash/
Please report issues to http://code.google.com/p/gaforflash/issues/ (precise the version 1.0.1.319)

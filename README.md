psuFusionSetup
==============

Script to configure two internal drives as a CoreStorage LVG and Fusion Drive.

The code creates an array of all internal drives, then checks to see which one is an SSD and which one is a HDD. Once set, it uses the two drives to create a new CoreStorage Logical Volume Group, then a Fusion Drive. 

Limitations
=============
Will not work with two HDDs or two SSDs.
Will not work with more than two internal drives.
Will erase hard disks with extreme prejudice. 

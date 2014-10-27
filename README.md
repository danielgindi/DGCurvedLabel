DGCurvedLabel
=============

A UILabel that curves the text around the specified radius.

I took Apple's sample code of "CoreTextArcCocoa", and adjusted it to fit my needs. What I did is make sure I can have the text curve on the outside of the arc as well of on the inside, have control of the angle, and have correct letter spacing.

There are currently 3 simple properties (in addition to the `UILabel` ones):
* `radius` is the radius for the arc on which we curve the text
* `rotation` adjust the rotation of the text
* `textInside` set the text to curve on the *inside* of the curve instead of on the outside. The default is `NO` which means that it's on the outside.

Usage:
* Use as usual for `UILabel` either by code or by Interface Builder.
* If you use in Interface Builder, just drag a `UILabel` to your view, and change its class to `DGCurvedLabel`.
* If you want to adjust the properties in Interface Builder without touching code, you could just go to "Identity Inspector" on the right, and add the attributes under "User Defined Runtime Attributes"

## Me
* Hi! I am Daniel Cohen Gindi. Or in short- Daniel.
* danielgindi@gmail.com is my email address.
* That's all you need to know.

## Help

If you like what you see here, and want to support the work being done in this repository, you could:
* Actually code, and issue pull requests
* Spread the word
* 
[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=CHRDHZE79YTMQ)

## License

All the code here is under MIT license. Which means you could do virtually anything with the code.
I will appreciate it very much if you keep an attribution where appropriate.

    The MIT License (MIT)
    
    Copyright (c) 2013 Daniel Cohen Gindi (danielgindi@gmail.com)
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

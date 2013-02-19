# Notes for parsing JPEGs, EXIF

````
192 #define M_SOF0  0xC0            // Start Of Frame N
193 #define M_SOF1  0xC1            // N indicates which compression process
194 #define M_SOF2  0xC2            // Only SOF0-SOF2 are now in common use
195 #define M_SOF3  0xC3
197 #define M_SOF5  0xC5            // NB: codes C4 and CC are NOT SOF markers
198 #define M_SOF6  0xC6
199 #define M_SOF7  0xC7
201 #define M_SOF9  0xC9
202 #define M_SOF10 0xCA
203 #define M_SOF11 0xCB
205 #define M_SOF13 0xCD
206 #define M_SOF14 0xCE
207 #define M_SOF15 0xCF
216 #define M_SOI   0xD8            // Start Of Image (beginning of datastream)
217 #define M_EOI   0xD9            // End Of Image (end of datastream)
218 #define M_SOS   0xDA            // Start Of Scan (begins compressed data)
224 #define M_JFIF  0xE0            // Jfif marker
225 #define M_EXIF  0xE1            // Exif marker
254 #define M_COM   0xFE            // COMment
219 #define M_DQT   0xDB
196 #define M_DHT   0xC4
221 #define M_DRI   0xDD
237 #define M_IPTC  0xED            // IPTC marker
````

## Notes on Padding

From http://stackoverflow.com/questions/4585527/detect-eof-for-jpg-images:

Well, there's no guarantee that you wont find FFD9 within a jpeg image. The best way you can find the end of a jpeg image is to parse it. Every marker, except for FFD0 to FFD9 and FF01(reserved), is immediately followed by a length specifier that will give you the length of that marker segment, including the length specifier but not the marker. FF00 is not a marker, but for your purposes you can treat it as marker without a length specifier.

The length specifier is two bytes long and it's big endian. So what you'll do is search for FF, and if the following byte is not one of 0x00, 0x01 or 0xD0-0xD8, you read the length specifier and skips forward in the stream as long as the length specifier says minus two bytes.

Also, every marker can be padded in the beginning with any number of FF's.

When you get to FFD9 you're at the end of the stream.

Of course you could read the stream word by word, searching for FF if you want performance but that's left as an exercise for the reader. ;-)


## EXIF ROTATION stuff

// 1 - "The 0th row is at the visual top of the image,    and the 0th column is the visual left-hand side."
// 2 - "The 0th row is at the visual top of the image,    and the 0th column is the visual right-hand side."
// 3 - "The 0th row is at the visual bottom of the image, and the 0th column is the visual right-hand side."
// 4 - "The 0th row is at the visual bottom of the image, and the 0th column is the visual left-hand side."

// 5 - "The 0th row is the visual left-hand side of of the image,  and the 0th column is the visual top."
// 6 - "The 0th row is the visual right-hand side of of the image, and the 0th column is the visual top."
// 7 - "The 0th row is the visual right-hand side of of the image, and the 0th column is the visual bottom."
// 8 - "The 0th row is the visual left-hand side of of the image,  and the 0th column is the visual bottom."

// Note: The descriptions here are the same as the name of the command line
// option to pass to jpegtran to right the image

static const char * OrientTab[9] = {
    "Undefined",
    "Normal",           // 1
    "flip horizontal",  // left right reversed mirror
    "rotate 180",       // 3
    "flip vertical",    // upside down mirror
    "transpose",        // Flipped about top-left <--> bottom-right axis.
    "rotate 90",        // rotate 90 cw to right it.
    "transverse",       // flipped about top-right <--> bottom-left axis
    "rotate 270",       // rotate 270 to right it.
};

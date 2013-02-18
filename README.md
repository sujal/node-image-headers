# ImageHeaders

This is a simple class that can be used with a stream to read
all the metadata from an image file without storing the entire file in memory.

Typically, most libraries in Node take in the stream, save it somewhere
(either a Buffer or to disk), then hand the image file off to an external library.

We have a image uploader service that basically proxies through the stream
directly to S3 - we don't want to hit our disk at all. So, this accomplishes this.


# ImageHeaders

This is a simple class that can be used with a stream to read
all the metadata from an image file without storing the entire file in memory.

Typically, most libraries in Node take in the stream, save it somewhere
(either a Buffer or to disk), then hand the image file off to an external library.

We have a image uploader service that basically proxies through the stream
directly to S3 - we don't want to hit our disk at all. This was the only way we could
hit that goal and still get our metadata.

## Usage

````
npm install image-headers
````

See the test file for how we are using it. Here's the key snippet:

````
image_headers = new ImageHeaders()

  new DataReader(file_name)
    .on "error", (error) ->
      console.log ("error: " + error)
      return callback(error)
    .on "byte", (b) ->
      # console.log ("byte: " + b)
      image_headers.add_bytes(b) unless image_headers.finished
    .on "end", () ->
      # console.log ("EOF");
      image_headers.finish (err, image_headers) ->
        return callback(err, image_headers)
    .read()
````

That's in CoffeeScript.

The `finish` call is important - it's what processes the EXIF tags (and
in the future anything similar that can benefit from an external library). This
keeps our code simpler from having us stream and parse EXIF on the fly. No library
does this well, as far as I can find.

## TODO

- performance and general cleanup. This was a weekend hack (really a 24 hour one) and it shows.
- clean up internals and exposed data structures. Right now, it's all properties on the object.
- add support for additional metadata, including GPS and Camera model, as top level features

## License

See the LICENSE file for details, but short version: MIT License.


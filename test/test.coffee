# File: test.js
# Description: Test file for node-image-headers
# Copyright: 2013 Sujal Shah
# Author: Sujal Shah

ImageHeaders = require("image_headers")


read_file = (file_name, callback) ->

  image_headers = new ImageHeaders()

  new BufferedReader (file_name)
    .on "error", (error) ->
      console.log ("error: " + error)
      return callback(error)
    .on "byte", (b) ->
      console.log ("byte: " + b)
      image_headers.add_bytes(b) unless image_headers.finished
    .on "end", () ->
      console.log ("EOF");
      return callback(null, image_headers)
    .read()

describe "ImageHeaders", () ->

  it "should give me the size of a JPG", (done) ->
    read_file "test_image.jpg", (err, image_headers) ->


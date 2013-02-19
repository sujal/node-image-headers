# File: test.js
# Description: Test file for node-image-headers
# Copyright: 2013 Sujal Shah
# Author: Sujal Shah

ImageHeaders = require("image_headers")
reader = require ("buffered-reader")
should = require("should")
DataReader = reader.DataReader


read_file = (file_name, callback) ->

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

describe "ImageHeaders", () ->

  it "should give me the size of a JPG w/ exif", (done) ->
    read_file "test/samples/IMG_9111.JPG", (err, image_headers) ->
      should.not.exist(err)
      should.exist(image_headers)
      should.exist(image_headers.mode)
      image_headers.mode.should.eql(ImageHeaders.modes.jpeg)
      image_headers.width.should.eql(3264)
      image_headers.height.should.eql(2448)
      should.exist(image_headers.exif_data)
      done()

  it "should give me the size of a photoshop JPG", (done) ->
    read_file "test/samples/F.jpg", (err, image_headers) ->
      should.not.exist(err)
      should.exist(image_headers)
      should.exist(image_headers.mode)
      image_headers.mode.should.eql(ImageHeaders.modes.jpeg)
      image_headers.width.should.eql(1600)
      image_headers.height.should.eql(1600)
      done()

  it "should give me the size of a JPG w/ exif & rotation (8)", (done) ->
    read_file "test/samples/IMG_9114.JPG", (err, image_headers) ->
      should.not.exist(err)
      should.exist(image_headers)
      should.exist(image_headers.mode)
      image_headers.mode.should.eql(ImageHeaders.modes.jpeg)
      should.exist(image_headers.exif_data)
      image_headers.width.should.eql(2448)
      image_headers.height.should.eql(3264)
      done()

  it "should give me the size of a JPG w/ exif & rotation (6)", (done) ->
    read_file "test/samples/IMG_9098.JPG", (err, image_headers) ->
      should.not.exist(err)
      should.exist(image_headers)
      should.exist(image_headers.mode)
      image_headers.mode.should.eql(ImageHeaders.modes.jpeg)
      should.exist(image_headers.exif_data)
      image_headers.width.should.eql(2448)
      image_headers.height.should.eql(3264)
      done()

  it "should give me the size of a JPG w/ exif & rotation (3)", (done) ->
    read_file "test/samples/IMG_9116.JPG", (err, image_headers) ->
      should.not.exist(err)
      should.exist(image_headers)
      should.exist(image_headers.mode)
      image_headers.mode.should.eql(ImageHeaders.modes.jpeg)
      should.exist(image_headers.exif_data)
      image_headers.width.should.eql(3264)
      image_headers.height.should.eql(2448)
      done()

  it "should give me the size of a PNG", (done) ->
    read_file "test/samples/F.png", (err, image_headers) ->
      should.not.exist(err)
      should.exist(image_headers)
      should.exist(image_headers.mode)
      image_headers.mode.should.eql(ImageHeaders.modes.png)
      should.not.exist(image_headers.exif_data)
      should.exist(image_headers.width)
      should.exist(image_headers.height)
      image_headers.width.should.eql(1600)
      image_headers.height.should.eql(1600)
      done()

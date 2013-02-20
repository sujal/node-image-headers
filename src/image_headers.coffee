# File: image_headers.coffee
# Description: Main class file for image_headers library
# Copyright: 2013 Sujal Shah
# Author: Sujal Shah

MAX_SIZE = 32768

exif = require('exif')

class ImageHeaders
  @modes:
    jpeg: "jpeg"
    gif: "gif"
    tiff: "tiff"
    png: "png"
  @orientations:
    landscape: "landscape"
    portrait: "portrait"
  constructor: () ->
    @finished = false
    @buffer = new Buffer(MAX_SIZE)
    @exif_buffer = null
    @exif_offset = 0
    @exif_bytes = 0
    @mode = null
    @buffer_index = 0
    @stream_index = 0
    @jpeg = {
      marker: 0
      marker_offset: 0
      marker_size: 0
    }
    @png = {
      start: 0
      length: 0
    }
    @height = null
    @width = null
    @exif_orientation = null
    @final_orientation = null


  add_bytes: (bytes) ->
    return if this.finished == true
    if (@buffer_index >= MAX_SIZE)
      # console.log @buffer
      this.finished = true
      return

    bytes = [bytes] if (typeof(bytes) == "number")

    for b in bytes
      if (@exif_bytes == 0)
        @buffer[@buffer_index] = b
        @route_byte(b)
        @buffer_index++
      else
        @exif_buffer.writeUInt8(b, @exif_offset)
        @exif_offset++
        @exif_bytes--
      @stream_index++

  finish: (callback) ->
    local_this = this
    if (@mode == ImageHeaders.modes.jpeg)
      if (@exif_buffer? && @exif_buffer.toString("utf-8", 0, 4) == "Exif")
        # console.log @exif_buffer.length
        new exif.ExifImage {exif_buffer: @exif_buffer}, (err, exif_data) ->

          if (exif_data? && exif_data.image?)
            orientation_tag = exif_data.image.filter (tag) ->
              return tag.tagName == "Orientation"

            if (orientation_tag.length == 1)
              local_this.orientation = orientation_tag[0].value
              if (local_this.orientation == 6 || local_this.orientation == 8)
                temp_w = local_this.width
                local_this.width = local_this.height
                local_this.height = temp_w


            local_this.exif_data = exif_data
          return callback(err, local_this)
      else
        return
    else
      return callback(null, local_this)


  route_byte: (b) ->
    switch @mode
      when ImageHeaders.modes.jpeg
        @check_jpeg_state(b,@buffer_index)
      when ImageHeaders.modes.gif
        @check_gif_state(b,@buffer_index)
      when ImageHeaders.modes.tiff
        @check_tiff_state(b,@buffer_index)
      when ImageHeaders.modes.png
        @check_png_state(b,@buffer_index)
      else
        @identify_format(b)

  check_jpeg_state: (b, i) ->
    # console.log "#{@jpeg.marker_section_offset} #{b}"
    # console.log("#{b} #{@jpeg.marker}")
    if (@jpeg.marker == 0 && b == 255)
      # marker on
      @jpeg.marker = b
      return
    else if @jpeg.marker == 255
      # we have a marker!
      # console.log "Marker is #{b} - #{@stream_index}(#{@buffer_index})" if b != 0

      switch b
        when 0x00, 0x01, 0xD0, 0xD1, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xFF
          @clear_jpeg_marker() # reset because we ain't got nothing interesting here.
          return
        else
          @jpeg.marker = b
          @jpeg.marker_offset = i
          @jpeg.marker_size = 0

    # after here, marker isn't 0xFF, and we should be in a valid state

    # check for SOS
    if (@jpeg.marker == 0xDA && @jpeg.marker_offset - i == 0)
      # console.log "SOS marker at #{@stream_index}"
      @finished = true
      return

    position = i - @jpeg.marker_offset
    if (position == 2)
      # we're getting a length
      length = @buffer.readUInt16BE(@jpeg.marker_offset+1)
      @jpeg.marker_size = length
      switch @jpeg.marker
        when 0xE1 #EXIF
          if (!@exif_buffer?)
            @exif_bytes = @jpeg.marker_size-2 #lenght includes the 2 bytes already read in
            @exif_buffer = new Buffer(@exif_bytes)
            # console.log "EXIF BYTES #{@exif_bytes}"
            @clear_jpeg_marker()

    else
      if (@jpeg.marker_size > 0 && position == @jpeg.marker_size)

        # done reading marker - process it
        switch @jpeg.marker
          when 0xC0,0xC1,0xC2,0xC3,0xC5,0xC6,0xC7,0xC9,0xCA,0xCB,0xCD,0xCE,0xCF
            @parse_jpeg_sofn()

        @clear_jpeg_marker()

  check_gif_state: (b, i) ->
    if (i == 10)
      # console.log @buffer.toString("hex", 0, 10)
      @width = @buffer.readUInt16LE(6)
      @height = @buffer.readUInt16LE(8)
      @finished = true

  check_png_state: (b, i) ->
    # console.log b if (i < 8)
    return if i < 8 # if we're still in the PNG magic number
    if (@png.start == 0)
      @png.start = i
      # console.log "starting chunk: #{@png.start}"
      return 0

    offset = i-@png.start
    # if (offset < 3)
      # console.log "---"

    switch offset
      when 3
        # we have a length
        length = @buffer.readUInt32BE(@png.start)
        @png.length = length
        # console.log "chunk length: #{length}"
      when 7
        # we have a chunk!
        @png.marker = @buffer.toString("utf8", @png.start+4, @png.start+8)
        # console.log "chunk marker: #{@png.marker}"
      when @png.length+8
        if @png.marker == "IHDR"
          # console.log @buffer.toString("hex", @png.start+8, @png.start+8+@png.length)
          @width = @buffer.readUInt32BE(@png.start+8)
          @height = @buffer.readUInt32BE(@png.start+12)
          @finished = true
      when @png.length+12
        @clear_png_marker()

  check_tiff_state: (b, i) ->
    # unsupported for now... probably can hand this to EXIF code, eventually :-/
    @height = 0
    @width = 0
    @finished = true



  identify_format: (b) ->
    if (@stream_index == 1)
      if (@buffer[0] == 0xFF && @buffer[1] == 0xD8)
        @mode = ImageHeaders.modes.jpeg
    else if (@stream_index == 2)
      buf_as_string = @buffer.toString("utf8", 0, 3)
      if (buf_as_string == "GIF")
        @mode = ImageHeaders.modes.gif
      else if (buf_as_string == "II*" || buf_as_string == "MM*")
        @mode = ImageHeaders.modes.tiff
    else if (@stream_index == 7)
      if (@buffer.toString("hex", 0, 8) == "89504e470d0a1a0a") # this is the signature for PNG - \211PNG\r\n\032\n
        @mode = ImageHeaders.modes.png

    # failsafe - if we haven't ID'd the file in 10 bytes, abort
    if (@stream_index > 10)
      @finished = true
      return

    if (@mode?)
      # replay
      for i in [0..@stream_index]
        @route_byte(@buffer[i], i)

  # JPEG SUPPORT
  clear_jpeg_marker: () ->
    @jpeg.marker = 0
    @jpeg.marker_offset = 0
    @jpeg.marker_size = 0

  parse_jpeg_sofn: () ->
    @height = @buffer.readUInt16BE(@jpeg.marker_offset+4)
    @width = @buffer.readUInt16BE(@jpeg.marker_offset+6)

  # PNG SUPPORT
  clear_png_marker: () ->
    @png.start = 0
    @png.length = 0
    @png.marker = null












module.exports = ImageHeaders
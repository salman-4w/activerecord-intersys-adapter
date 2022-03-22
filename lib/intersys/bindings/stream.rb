module Intersys
  module Reflection
    class Stream < Intersys::Object
      # Maximum block size can be readed with one read call is 31KB,
      # but when we reading PDF it has strange artifacts when block size great than 2KB.
      BLOCK_SIZE = 2048.freeze # 2KB

      # Read a specified number of characters starting at the current position in the stream.
      def read(size)
        intersys_call 'Read', size
      end

      # Read a whole stream content by BLOCK_SIZE while not get content size
      def read_all
        left_to_read = size
        return nil if left_to_read.zero?

        result = ""
        position = 0

        rewind
        begin
          to_read = left_to_read > BLOCK_SIZE ? BLOCK_SIZE : left_to_read
          position += to_read
          left_to_read -= to_read

          result << read(to_read)
          move_to(position)
        end while left_to_read > 0

        result
      end

      # Append data to the stream, starting at the current position. Overwrites existing data if
      # the position is not set to the end of the stream.
      def write(content)
        intersys_call 'Write', content
      end

      # Move to the beginning of the stream.
      def rewind
        intersys_call 'Rewind'
      end

      # Move to a given position in the stream.
      def move_to(position)
        intersys_call 'MoveTo', position
      end

      # Move to the end of the stream.
      def move_to_end
        intersys_call 'MoveToEnd'
      end

      # Copy the contents of a source stream into this stream.
      def copy_from(stream)
        raise 'Not implemented'
      end

      # The default storage location (directory or global)
      def location
        intersys_get '%Location'
      end

      # Set to true when a Read encounters the end of the data source.
      def at_end?
        intersys_get('AtEnd')
      end

      # The current size of the stream (in bytes or characters, depending on the type of stream).
      def size
        intersys_get 'Size'
      end
    end

    class GlobalCharacterStream < Stream
      class_name '%Library.GlobalCharacterStream'

      def to_s
        rewind
        read_all.to_s
      end
    end

    class GlobalBinaryStream < Stream
      class_name '%Library.GlobalBinaryStream'

      def data
        read_all
      end
    end

    # NewFileName - Specify a filename for a %FileCharacterStream or %FileBinaryStream property.
    # Id - The unique identifier for an instance of a stream within the extent specified by %Location.
  end
end

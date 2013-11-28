
require "rubygems"
require "ffi"

require 'idev/libc'

module FFI
  class Pointer
    def read_unbound_array_of_string
      #Reads an array of strings terminated by an empty string (i.e.
      #not length bound
      ary = []
      size = FFI.type_size(:string)
      tmp = self
      begin
        s = tmp.read_pointer.read_string
        ary << s
        tmp += size
      end while !tmp.read_pointer.null?
      ary
    end
  end

  class MemoryPointer < Pointer
    def self.from_bytes(data)
      if block_given?
        new(data.size) do |p|
          p.write_bytes(data)
          yield(p)
        end
      else
        p = new(data.size)
        p.write_bytes(data)
        p
      end
    end
  end
end

module Idev
  module C
    extend FFI::Library
    ffi_lib 'imobiledevice'

    typedef :pointer, :idevice_t
    typedef :pointer, :idevice_connection_t

    IdeviceError = enum(
      :SUCCESS,               0,
      :INVALID_ARG,          -1,
      :UNKNOWN_ERROR,        -2,
      :NO_DEVICE,            -3,
      :NOT_ENOUGH_DATA,      -4,
      :BAD_HEADER,           -5,
      :SSL_ERROR,            -6,
    )

    typedef IdeviceError, :idevice_error_t

    # discovery (synchronous)
    attach_function :idevice_set_debug_level, [:int], :void
    attach_function :idevice_get_device_list, [:pointer, :pointer], :idevice_error_t
    attach_function :idevice_device_list_free, [:pointer], :idevice_error_t

    # device structure creation and destruction
    attach_function :idevice_new, [:pointer, :string], :idevice_error_t
    attach_function :idevice_free, [:pointer], :idevice_error_t

    # connection/disconnection
    attach_function :idevice_connect, [:idevice_t, :uint16, :pointer], :idevice_error_t
    attach_function :idevice_disconnect, [:idevice_connection_t], :idevice_error_t

    # communication
    attach_function :idevice_connection_send, [:idevice_connection_t, :pointer, :uint32, :pointer], :idevice_error_t
    attach_function :idevice_connection_receive_timeout, [:idevice_connection_t, :pointer, :uint32, :pointer, :uint], :idevice_error_t
    attach_function :idevice_connection_receive, [:idevice_connection_t, :pointer, :uint32, :pointer], :idevice_error_t

    # misc
    attach_function :idevice_get_handle, [:idevice_t, :pointer], :idevice_error_t
    attach_function :idevice_get_udid, [:idevice_t, :pointer], :idevice_error_t
  end
end


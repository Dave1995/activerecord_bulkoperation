require 'oci8'

#--
# bindtype.rb -- OCI8::BindType
#
# Copyright (C) 2009-2011 KUBO Takehiro <kubo@jiubao.org>
#++

#
class OCI8
  module BindType

    class String
      # 1333 <= ceil(4000 / 3). 4000 is max size of char. 3 is NLS ratio of UTF-8.
      @@minimum_bind_length = 1333

      def self.minimum_bind_length
        @@minimum_bind_length
      end

      def self.minimum_bind_length=(val)
        @@minimum_bind_length = val
      end

      def self.create(con, val, param, max_array_size)
        case param
        when Hash
          param[:length_semantics] = OCI8::properties[:length_semantics] unless param.has_key? :length_semantics
          unless param[:length]
            if val.is_a?(Array) && val.any?
              max = 0
              val.each do |elem|
                length = self.get_length(elem, param)
                max = length if max < length
              end
              param[:length] = max
            else
              param[:length] = self.get_length(val, param)
            end
          end
          # use the default value when :nchar is not set explicitly.
          param[:nchar] = OCI8.properties[:bind_string_as_nchar] unless param.has_key?(:nchar)
        when OCI8::Metadata::Base
          case param.data_type
          when :char, :varchar2
            length_semantics = OCI8.properties[:length_semantics]
            if length_semantics == :char
              length = param.char_size
            else
              length = param.data_size * OCI8.nls_ratio
            end
            param = {
              :length => length,
              :length_semantics => length_semantics,
              :nchar => (param.charset_form == :nchar),
            }
          when :raw
            # HEX needs twice space.
            param = {:length => param.data_size * 2}
          else
            param = {:length => @@minimum_bind_length}
          end
        end
        self.new(con, val, param, max_array_size)
      end

      private

      def self.get_length(val, param)
        if val.respond_to? :to_str
          val = val.to_str
          if param[:length_semantics] == :char
            # character semantics
            return val.size
          else
            # byte semantics
            if OCI8.encoding != val.encoding
              # If the string encoding is different with NLS_LANG character set,
              # convert it to get the length.
              val = val.encode(OCI8.encoding)
            end
            return val.bytesize
          end
        else
          return @@minimum_bind_length
        end
      end
    end

  end

end
require 'ffi'
# require 'narray'

class Vecsearch
  class GTETiny
    module CStdio
      extend FFI::Library
      ffi_lib 'c'

      attach_function :fflush, [:pointer], :int
    end

    module Bert
      extend FFI::Library
      ffi_lib 'libbert.dylib'

      attach_function :bert_load_from_file, [:string], :pointer
      attach_function :bert_n_embd, [:pointer], :int
      attach_function :bert_encode_batch, [:pointer, :int, :int, :int, :pointer, :pointer], :void
    end

    GTE_BIN = File.expand_path('gte-tiny-q4_1.ggml.bin', __dir__)
    MAX_TOKENS = 512

    def initialize(fname=GTE_BIN)
      suppress_streams do
        @ctx = Bert.bert_load_from_file(fname)
        @n_embd = Bert.bert_n_embd(@ctx)
        sleep(0.1)
      end
    end

    def suppress_streams
      prev_stdout = STDOUT.dup
      STDOUT.reopen("/dev/null", "w")
      STDOUT.sync = true
      yield
    ensure
      CStdio.fflush(nil) # Regular STDOUT.flush doesn't do it.
      STDOUT.reopen(prev_stdout)
    end

    def encode(sentence, n_threads: 1)
      # Encode the sentence into token embeddings
      token_embeddings = encode_batch([sentence], n_threads: 1)

      # Pool the token embeddings into a sentence embedding
      # For simplicity, we'll use an attention mask of all ones
      attention_mask = Array.new(token_embeddings.first.length, 1)
      # sentence_embedding = mean_pooling(token_embeddings, attention_mask)
      # sentence_embedding
      token_embeddings
    end

    def encode_batch(input, n_threads: 1)
      # Create an array of pointers to the input strings
      input_ptrs = input.map { |str| FFI::MemoryPointer.from_string(str) }

      # Create a pointer to the array of input pointers
      input_ptrs_ptr = FFI::MemoryPointer.new(:pointer, input_ptrs.length)
      input_ptrs_ptr.write_array_of_pointer(input_ptrs)

      # Create an output buffer for each input string
      output_ptrs = input.map { FFI::MemoryPointer.new(:float, @n_embd) }

      # Create a pointer to the array of output pointers
      output_ptrs_ptr = FFI::MemoryPointer.new(:pointer, output_ptrs.length)
      output_ptrs_ptr.write_array_of_pointer(output_ptrs)

      Bert.bert_encode_batch(@ctx, n_threads, MAX_TOKENS, input.length, input_ptrs_ptr, output_ptrs_ptr)

      # Convert the output buffers to Ruby arrays
      output = output_ptrs.map { |ptr| ptr.read_array_of_float(@n_embd) }

      output
    end

    # def mean_pooling(token_embeddings, attention_mask)
    #   token_embeddings_na = NArray.to_na(token_embeddings)
    #   attention_mask_na = NArray.to_na(attention_mask)

    #   input_mask_expanded = attention_mask_na.expand_dims(-1).repeat(token_embeddings_na.shape[-1], -1)

    #   sentence_embeddings = (token_embeddings_na * input_mask_expanded).sum(1) / input_mask_expanded.sum(1).clip(1e-9)

    #   sentence_embeddings.to_a
    # end
  end
end

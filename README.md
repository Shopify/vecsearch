# Vecsearch

Vecsearch is an all-in-one vector search library for ruby that uses a 4-bit (Q4_1) quantization of
[gte-tiny](https://huggingface.co/TaylorAI/gte-tiny) by using [bert.cpp](https://github.com/skeskinen/bert.cpp) (a
[GGML](https://ggml.ai/) implementation of [BERT](https://arxiv.org/abs/1810.04805) via
[FFI](https://github.com/ffi/ffi)), and an in-process [FAISS](https://github.com/facebookresearch/faiss) index.

Vecsearch embeds pre-built dynamic libraries for `libbert` and `libggml`, as well as a quantized model checkpoint for
gte-tiny (total size: 14MB).

Currently only ARM64 macOS is supported, purely because I haven't bothered to build other dylibs yet. There is nothing
difficult about this.

## Usage

```ruby
gem 'vecsearch'
```

```ruby
Vecsearch.new('hello', 'goodbye').nearest('howdy') #=> 'hello'
```

```ruby
require 'vecsearch'

vs = Vecsearch.new
vs << "sharks with freaking laser beams"
vs << "hello"
vs << "the sky is green"

puts(vs.nearest("hey there")) # => "hello"
```

## Bugs

Yes

## Limitations / TODO

* I haven't got the mean-pooling part of gte-tiny working. It seems to work well
  enough without it but we should do that and assert that ours generates
  approximately the same embedding as the canonical model.
* Batching looks unimplemented in bert.cpp; it would be nice for prefilling the
  index.
* Add more builds for platforms other than darwin/amd64.
* Probably add a way to fetch an unquantized model, maybe other models entirely?

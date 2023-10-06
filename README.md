# Vecsearch

Vecsearch is an all-in-one semantic search library for ruby that uses a 4-bit (Q4_1) quantization of
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
vs << "hello"
vs << "behold, a non-sequitur"
vs << "how's it goin'"

puts(vs.query("hey there", 2).inspect)
# ["hello", "how's it goin'"]
```

## Bugs

Haha. Yes.

## Performance

All of these are haphazardly measured on my 2021 M1 MacBook Pro.

* Embedding a 1-token document: 1.2ms
* Embedding a 512-token document: 72ms
* Adding a document to the database: negligible
* Querying an empty database: negligible
* Querying a database with 1000 entries: negligible (plus time to embed query)
* Querying a database with 10000 entries: 300μs (plus time to embed query)
* Querying a database with 100000 entries: 3.2ms (plus time to embed query)

## Limitations / TODO

* Trying to embed a document over 512 tokens long segfaults.
* I haven't got the mean-pooling part of gte-tiny working. It seems to work well
  enough without it but we should do that and assert that ours generates
  approximately the same embedding as the canonical model.
* Batching looks unimplemented in bert.cpp; it would be nice for prefilling the
  index.
* Add more builds for platforms other than darwin/amd64.
* Probably add a way to fetch an unquantized model, maybe other models entirely?

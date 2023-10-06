require 'vecsearch/version'
require 'faiss'
require_relative 'gte_tiny'

class Vecsearch

  def initialize(records=[])
    @faiss = Faiss::IndexFlatL2.new(384)
    @gte = GTETiny.new
    @texts = []
    records.each { |rec| self << rec }
  end

  def <<(str)
    emb = @gte.encode(str)
    @texts << str
    @faiss.add(emb)
  end

  def nearest(str) = query(str, 1)[0]

  def query(str, n)
    emb = @gte.encode(str)
    _scores, indexes = @faiss.search(emb, 2)
    [].tap { |res| indexes.each { |idx| res << @texts[idx] } }
  end
end

require 'vecsearch/version'
require 'faiss'

class Vecsearch
  autoload(:GTETiny, 'vecsearch/gte_tiny')

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

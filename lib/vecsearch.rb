require 'vecsearch/version'
require 'faiss'

class Vecsearch
  autoload(:GTETiny, 'vecsearch/gte_tiny')

  MAGIC = 'VS01'.freeze

  def initialize(*records)
    @faiss = Faiss::IndexFlatL2.new(384)
    @gte = GTETiny.new
    @texts = []
    add(*records) if records.any?
  end

  def <<(str)
    emb = @gte.encode(str)
    @texts << str
    @faiss.add(emb)
  end

  def add(*records)
    emb = @gte.encode_batch(records)
    @texts.concat(records)
    @faiss.add(emb)
  end

  def nearest(str) = query(str, 1)[0]

  def query(str, n)
    emb = @gte.encode(str)
    _scores, indexes = @faiss.search(emb, 2)
    [].tap { |res| indexes.each { |idx| res << @texts[idx] } }
  end

  def save_to_disk(fname)
    File.open(fname, 'wb') { |f| dump(f) }
  end

  def self.load_from_disk(fname)
    File.open(fname, 'rb') { |f| load(f) }
  end

  def dump(stream)
    n = stream.write(MAGIC)
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'faiss.index')
      @faiss.save(path)
      f = File.open(path, 'r')
      sz = f.size
      n += stream.write([sz].pack('L'))
      n += stream.write(f.read)
      f.close
    end
    n += stream.write(@texts.join("\x00"))
    n
  end

  def self.load(stream)
    stream = StringIO.new(stream) if stream.is_a?(String)
    # Read the magic bytes
    magic = stream.read(4)
    unless magic == MAGIC
      raise "Invalid magic bytes: #{magic.inspect}"
    end
    faiss_size = stream.read(4).unpack('L').first
    faiss_index = nil
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'faiss.index')
      f = File.open(path, 'w')
      f.write(stream.read(faiss_size))
      f.close
      faiss_index = Faiss::Index.load(path)
    end
    texts = stream.read.split("\x00")

    inst = Vecsearch.allocate
    inst.instance_variable_set(:@faiss, faiss_index)
    inst.instance_variable_set(:@texts, texts)
    inst.instance_variable_set(:@gte, GTETiny.new)
    inst
  end
end

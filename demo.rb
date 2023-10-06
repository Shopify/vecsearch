require 'faiss'
require_relative 'gte_tiny'

class VectorSearchIndex
end

vsi = VectorSearchIndex.new
vsi << "sharks with freaking laser beams"
vsi << "hello"
vsi << "the sky is green"

puts("nearest record to 'hey there': #{vsi.nearest("hey there")}")

t = Time.now
N = 1000
N.times { vsi.nearest("hey there") }
elapsed = Time.now - t
puts "#{(elapsed / (N/1000.0)).round(1)} ms per query"


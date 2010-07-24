require 'classes'
require 'set'
require 'benchmark'
require 'jruby-prof'


Neo4j::Config[:storage_path] = '/Users/jplewicke/rivulet/dbneo'


def urls(enum)
  enum.collect do |n| 
    case n.obj
    when Asset
      "%s_<asset>" %n.obj.url
    when Offer
      "%s_(offered)" % n.obj.offering.url
    end
  end
end

def urls2(enum)
  enum.collect do |n| 
    case n
    when Asset
      "#{n.url}_<asset>"
    when Offer
      "#{n.offering.url}_(offered #{n.quantity})"
    end
  end
end


class BFSNode
  include Enumerable
  #Ignores predecessor path information in comparison and equality testing
  attr_accessor :obj, :pred
  @hash = nil
  
  def initialize(obj, pred=[])
    @obj = obj
    @pred = pred
  end
  
  def hash
    if @hash == nil
      @hash = @obj.hash
    end
    @hash
  end
  
  def ==(other)
    self .eql? other
  end
  
  def eql?(other)
    (self.hash == other.hash) && (other.class == self.class)
  end
  
  def each
    yield @obj
    @pred.each {|n| yield n}
  end
end
  
def find_asset(name)
  ret = nil
    Neo4j::Transaction.run do
    #  puts "Find all assets with URL #{name}"
      result = Asset.find(:url => name)
     result.each {|x| ret = x}
    end
  return ret
end

# Returns a list of 2-tuples of all other assets offered in exchange for the current
# asset, along with the quantity available of them along the best route.
def bfs_step(node, discovered=[])
  case node.obj
  when Asset
    all_offers = node.obj.sought_by.collect { |offer|
      BFSNode.new(offer.offering, BFSNode.new(offer,node))}
  when Offer
      new_node = BFSNode.new(node.obj.offering,node)
      if discovered.include?(new_node)
        []
      else
        [new_node]
      end
  else
      raise "Invalid type passed into bfs_step. %s" % node.obj.class
  end
end

def augmenting_path(offered,sought)
  discovered = Set.new [offered]
  
  visiting = Set.new([BFSNode.new(offered,[])])
  
  visiting.each do |node|
    if node.obj == sought
      return node
    end
    found = bfs_step(node, discovered)
    discovered.merge(found)
    visiting.merge(found)
  end
  return nil
end
  

asset_urls = ["jplewicke", 
  "silviogesell",
  "henrygeorge",
  "spiderman",
  "batman",
  "robin",
  "joker",
  "catwoman",
  "patrickhenry",
  "aynrand",
  "johnstossel",
  "robertpaine",
  "rogersherman",
  "johnhancock",
  "oliverwolcott",
  "johnpenn",
  "lymanhall",
  "josiahbartlett",
  "georgewashington",
  "thomasjefferson",
  "samadams",
  "benfranklin"]
  
  
25000.times do |i|
  asset_urls[i] = "Asset_#{i}$"
end

# max_flow()


sg_hours = find_asset(asset_urls[1])
jpl_hours = find_asset(asset_urls[0])
jpl_hours2 = find_asset(asset_urls[0])

#Find shortest-link way to trade sg_hours for jpl_hours.

assets = Array.new

Neo4j::Transaction.run do
  25000.times do |i|
    assets[i] = find_asset(asset_urls[i])
  end
end

10.time do |i|
  total = 0.0
  num = 0.0
  Neo4j::Transaction.run do
    j = rand(assets.size - 400)
    k = j + rand(500) - 300
    s = assets[j]
    o = s
    o = assets[k + rand(3)] until o != s
    num += 1
    total += Benchmark.realtime {
     puts urls2(augmenting_path(s, o).to_a.reverse) }
 end
 puts total / num
end    

return

Neo4j::Transaction.run do
  
 # puts urls(bfs_step(BFSNode.new(sg_hours)).collect {|n| bfs_step(n,[])}.flatten)
  puts Benchmark.realtime {
  puts urls2(augmenting_path(sg_hours, jpl_hours).to_a.reverse) }  
  #result = JRubyProf.profile do
  #  puts urls2(augmenting_path(jpl_hours, sg_hours).to_a.reverse)
  #end
  #JRubyProf.print_graph_html(result, "graph.html")
  
  puts Benchmark.realtime {
  puts urls2(augmenting_path(sg_hours, jpl_hours).to_a.reverse) }
  puts Benchmark.realtime {
  puts urls2(augmenting_path(sg_hours, jpl_hours).to_a.reverse) }
end

return
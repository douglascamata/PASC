require 'treetop'
require 'polyglot'
require './gramatica'
require './nos'
require './gerador'

class PascCompiler

  def initialize
    @pasc = PascParser.new
  end

  def compile(code)
    tree = @pasc.parse(code)
    raise "cannot parse code" if tree.nil?
    clean_tree(tree)
    p tree
    Gerador.new(tree).compile
  end

  def compile_and_run(code)
    compile(code).run
  end

  def clean_tree(root_node)
   return if(root_node.elements.nil?)
   root_node.elements.delete_if{|node| node.class.name == "Treetop::Runtime::SyntaxNode" }
   root_node.elements.each {|node| self.clean_tree(node) }
  end

end

['core', 'core/builder', 'execution_engine', 'transforms/scalar'].each do |filename|
  require "llvm/#{filename}"
end

class Gerador

  def initialize(syntax_tree)
    @tree = syntax_tree
  end

  def compile
    LLVM.init_x86
    @module = LLVM::Module.new("pasc")
    @builder = LLVM::Builder.new
    @function = @module.functions.add("main", [], LLVM::Int)
    @basic_block = @function.basic_blocks.append
    @builder.position_at_end(@basic_block)
    @locals = Hash.new

    generate_code

    @builder.ret LLVM::Int(0)

    p
    puts "-----------------------------------------------------------------"
    puts "Generating LLVM code..."
    puts "-----------------------------------------------------------------"
    @module.dump
    @module.verify
    p
    puts "-----------------------------------------------------------------"
    puts "Writting LLVM bitcode..."
    puts "-----------------------------------------------------------------"
    @module.write_bitcode('./codigo.ir')
    puts "Compiling LLVM bitcode to unoptimized machine code..."
    puts "-----------------------------------------------------------------"
    system 'llc codigo.ir -O0 -o codigo.s'
    system 'cat codigo.s'
    puts "-----------------------------------------------------------------"
    puts "Optimizing the machine code..."
    puts "-----------------------------------------------------------------"
    system 'llc codigo.ir -O2 -o codigo_otimizado.s'
    system 'cat codigo_otimizado.s'
    puts "-----------------------------------------------------------------"
    system 'rm -rf codigo.ir'
    self
  end

  def run
    # Execution objects.
    @engine = LLVM::JITCompiler.new(@module)
    @engine.run_function(@function)
  end

  private

  def generate_code
    @tree.generate_code @function, @locals, @builder, @basic_block
  end

end

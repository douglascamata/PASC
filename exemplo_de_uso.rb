require './pasc'
c = PascCompiler.new
codigo = File.new('codigo.pasc').read
c.compile_and_run codigo

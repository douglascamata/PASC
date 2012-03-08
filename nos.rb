require 'llvm'

module Pasc

    class Block < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        elements.each do |e|
          e.generate_code(function, globals, builder, block)
        end
      end
    end

    class Statement < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        elements.each do |e|
          e.generate_code(function, globals, builder, block)
        end
      end
    end

    class Assignment < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        if elements[1].kind_of? AssignmentOperator
          if globals[elements[0].text_value.to_sym].nil? # se nao existir na lista de simbolos
            double = builder.alloca(LLVM::Double, elements[0].text_value) # alocando um ponteiro para double
            result = elements[2].generate_code(function, globals, builder, block) # gera o codigo do lado direito para atribuir
            builder.store(result, double) # armazena result no ponteiro double
            globals[elements[0].text_value.to_sym] = double # guardando variável na lista
          else # caso ja exista na lista de simbolos
            result = elements[2].generate_code(function, globals, builder, block) # gera o código para atribuir
            builder.store(result, globals[elements[0].text_value.to_sym]) # quando o resultado na variavel ja usada
          end
        end
      end
    end

    class If < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        if_block = function.basic_blocks.append 'if' # bloco para o if
        comparative = elements[0].generate_code(function, globals, builder, block) # gerando o codigo da comparacao
        cont_block = function.basic_blocks.append 'cont_if' # bloco para continuar depois do if
        builder.cond(comparative, if_block, cont_block) # montando o desvio de blocos
        builder.position_at_end(if_block) # colocando cursor no bloco do if
        elements[1].generate_code(function, globals, builder, if_block) # gerando codigo de dentro do if
        builder.ret LLVM::Int(0) # finalizando o bloco do if
        builder.position_at_end(cont_block) # voltando o cursor para a continuaca do while
        block = cont_block # mudando o bloco atual para o de continuacao
      end
    end

    class While < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        while_block = function.basic_blocks.append 'while' # bloco para o codigo de dentro do while
        comparative = elements[0].generate_code(function, globals, builder, block) # gerando o codigo da comparacao
        cont_block = function.basic_blocks.append 'cont_while' # bloco para continuar depois do while
        builder.cond(comparative, while_block, cont_block) # montando o desvio de blocos
        builder.position_at_end(while_block) # colocando cursor no bloco do while
        elements[1].generate_code(function, globals, builder, while_block) # gerando codigo de dentro do while
        inside_comparative = elements[0].generate_code function, globals, builder, block # codigo da comparacao de dentro do while
        builder.cond(inside_comparative, while_block, cont_block) # montando o desvio de blocos
        builder.ret LLVM::Int(0) # finalizando o bloco do while
        builder.position_at_end(cont_block) # voltando o cursor para a continuacao do while
        block = cont_block # mudando o bloco atual para o de continuacao
      end
    end

    class For < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        for_block = function.basic_blocks.append 'for' # bloco para o codigo de dentro do for
        cont_block = function.basic_blocks.append 'cont_for' # bloco para continuar depois do for
        initialization = elements[0].generate_code function, globals, builder, block # gerando codigo da inicializacao
        comparative = elements[1].generate_code function, globals, builder, block # gerando codigo da comparacao (para primeira vez)
        builder.cond(comparative, for_block, cont_block) # gerando o codigo do desvio do comeco (para primeira vez)
        builder.position_at_end(for_block) # colocando o cursor dentro do bloco do for
        elements[3].generate_code function, globals, builder, for_block # gerando codigo de dentro do for
        increment = elements[2].generate_code function, globals, builder, block # gerando codigo do incremento
        inside_comparative = elements[1].generate_code function, globals, builder, block # codigo da comparacao de dentro do for
        builder.cond(inside_comparative, for_block, cont_block) # gerando o codigo do desvio do fim (depois da primeira vez)
        builder.ret LLVM::Int(0) # finalizando o bloco do for
        builder.position_at_end(cont_block) # voltando o cursor para a continuacao do for
        block = cont_block # mudando o bloco atual para o de continuacao
      end
    end

    class IntegerLiteral < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        LLVM::Double(text_value.to_f)
      end
    end

    class FloatLiteral < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        LLVM::Double(text_value.to_f)
      end
    end

    class StringLiteral < Treetop::Runtime::SyntaxNode
    end

    class Identifier < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        raise "Variavel nao iniciada." if globals[text_value.to_sym].nil?
        builder.load(globals[text_value.to_sym]) # llvm não consegue fazer comparações entre instruções
      end
    end

    class AssignmentOperator < Treetop::Runtime::SyntaxNode
    end

    class EqualityOperator < Treetop::Runtime::SyntaxNode
    end

    class InequalityOperator < Treetop::Runtime::SyntaxNode
    end

    class GreaterThanOperator < Treetop::Runtime::SyntaxNode
    end

    class LessThanOperator < Treetop::Runtime::SyntaxNode
    end

    class AdditionOperator < Treetop::Runtime::SyntaxNode
    end

    class SubtractionOperator < Treetop::Runtime::SyntaxNode
    end

    class MultiplicationOperator < Treetop::Runtime::SyntaxNode
    end

    class DivisionOperator < Treetop::Runtime::SyntaxNode
    end

    class Expression < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
          elements[0].generate_code(function, globals, builder, block)
      end
    end

    class ComparativeExpression < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        left_side = elements[0].generate_code(function, globals, builder, block)
        right_side = elements[2].generate_code(function, globals, builder, block)
        pred_by_comparative = {"==" => :oeq, "!=" => :one, ">" => :ogt, "<" => :olt}
        predicate = pred_by_comparative[elements[1].text_value]
        builder.fcmp(predicate, left_side, right_side.to_ptr, "comparative")
      end
    end

    class AdditiveExpression < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        left_operand = elements[0].generate_code function, globals, builder, block
        right_operand = elements[2].generate_code function, globals, builder, block
        return builder.fadd(left_operand, right_operand)
      end
    end

    class MultitiveExpression < Treetop::Runtime::SyntaxNode
      def generate_code(function, globals, builder, block)
        left_operand = elements[0].generate_code function, globals, builder, block
        right_operand = elements[2].generate_code function, globals, builder, block
        return builder.fmul(left_operand, right_operand) if elements[1].kind_of? MultiplicationOperator
        return builder.fdiv(LLVM::Double(left_operand), right_operand)
      end
    end

end

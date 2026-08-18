require "./expr"

module Slang
  module Expr
    class ParseError < Exception
    end

    # Recursive-descent parser for the restricted, Liquid-like expression
    # grammar (see slang-ct-rt-refactor.txt). Operates on the raw expression
    # text already extracted by Slang::Lexer's consume_line — not yet wired
    # into the main Lexer/Parser pipeline.
    class Parser
      private struct Tok
        enum Kind
          Ident
          Int
          Float
          Str
          TrueLit
          FalseLit
          NilLit
          Eq
          Ne
          AndAnd
          OrOr
          Lt
          Gt
          Le
          Ge
          Bang
          Dot
          Comma
          LParen
          RParen
          LBracket
          RBracket
          Eof
        end

        getter kind : Kind
        getter text : String

        def initialize(@kind, @text = "")
        end
      end

      def self.parse(source : String) : Node
        new(source).parse
      end

      def initialize(@source : String)
        @chars = @source.chars
        @pos = 0
        @tokens = [] of Tok
        @tokens = tokenize
        @index = 0
      end

      def parse : Node
        node = parse_or
        expect_eof
        node
      end

      private def parse_or : Node
        left = parse_and
        while current.kind.or_or?
          advance
          right = parse_and
          left = BinaryOp.new("||", left, right)
        end
        left
      end

      private def parse_and : Node
        left = parse_equality
        while current.kind.and_and?
          advance
          right = parse_equality
          left = BinaryOp.new("&&", left, right)
        end
        left
      end

      private def parse_equality : Node
        left = parse_comparison
        loop do
          op = case current.kind
               when .eq? then "=="
               when .ne? then "!="
               else           break
               end
          advance
          right = parse_comparison
          left = BinaryOp.new(op, left, right)
        end
        left
      end

      private def parse_comparison : Node
        left = parse_unary
        loop do
          op = case current.kind
               when .le? then "<="
               when .ge? then ">="
               when .lt? then "<"
               when .gt? then ">"
               else           break
               end
          advance
          right = parse_unary
          left = BinaryOp.new(op, left, right)
        end
        left
      end

      private def parse_unary : Node
        if current.kind.bang?
          advance
          UnaryOp.new("!", parse_unary)
        else
          parse_postfix
        end
      end

      private def parse_postfix : Node
        node = parse_primary
        loop do
          case current.kind
          when .dot?
            advance
            name = expect_ident
            if current.kind.l_paren?
              advance
              args = parse_args
              expect(Tok::Kind::RParen)
              node = Call.new(name, args, node)
            else
              node = Access.new(node, name)
            end
          when .l_bracket?
            advance
            idx = parse_or
            expect(Tok::Kind::RBracket)
            node = Index.new(node, idx)
          when .l_paren?
            advance
            args = parse_args
            expect(Tok::Kind::RParen)
            base = node
            raise ParseError.new("call target must be an identifier: #{@source}") unless base.is_a?(Var)
            node = Call.new(base.name, args, nil)
          else
            break
          end
        end
        node
      end

      private def parse_args : Array(Node)
        args = [] of Node
        return args if current.kind.r_paren?
        args << parse_or
        while current.kind.comma?
          advance
          args << parse_or
        end
        args
      end

      private def parse_primary : Node
        tok = current
        case tok.kind
        when .ident?
          advance
          Var.new(tok.text)
        when .int?
          advance
          Literal.new(tok.text.to_i64)
        when .float?
          advance
          Literal.new(tok.text.to_f64)
        when .str?
          advance
          Literal.new(tok.text)
        when .true_lit?
          advance
          Literal.new(true)
        when .false_lit?
          advance
          Literal.new(false)
        when .nil_lit?
          advance
          Literal.new(nil)
        when .l_paren?
          advance
          node = parse_or
          expect(Tok::Kind::RParen)
          node
        else
          raise ParseError.new("unexpected token #{tok.kind} in expression: #{@source}")
        end
      end

      private def current : Tok
        @tokens[@index]
      end

      private def advance
        @index += 1 if @index < @tokens.size - 1
      end

      private def expect(kind : Tok::Kind)
        raise ParseError.new("expected #{kind}, got #{current.kind} in expression: #{@source}") unless current.kind == kind
        advance
      end

      private def expect_ident : String
        raise ParseError.new("expected identifier, got #{current.kind} in expression: #{@source}") unless current.kind.ident?
        name = current.text
        advance
        name
      end

      private def expect_eof
        raise ParseError.new("unexpected trailing input in expression: #{@source}") unless current.kind.eof?
      end

      # --- tokenizer ---

      private def current_char : Char
        @chars[@pos]? || '\0'
      end

      private def peek_char : Char
        @chars[@pos + 1]? || '\0'
      end

      private def advance_char
        @pos += 1
      end

      PUNCTUATION = {
        '.' => Tok::Kind::Dot,
        ',' => Tok::Kind::Comma,
        '(' => Tok::Kind::LParen,
        ')' => Tok::Kind::RParen,
        '[' => Tok::Kind::LBracket,
        ']' => Tok::Kind::RBracket,
      }

      private def tokenize : Array(Tok)
        toks = [] of Tok
        loop do
          skip_whitespace
          tok = next_token
          toks << tok
          break if tok.kind.eof?
        end
        toks
      end

      private def next_token : Tok
        ch = current_char
        return Tok.new(:Eof) if ch == '\0'

        if kind = PUNCTUATION[ch]?
          advance_char
          return Tok.new(kind)
        end

        case ch
        when '!'       then tokenize_bang
        when '='       then tokenize_eq
        when '&'       then tokenize_amp
        when '|'       then tokenize_pipe
        when '<'       then tokenize_lt
        when '>'       then tokenize_gt
        when '"', '\'' then tokenize_string
        else                tokenize_literal(ch)
        end
      end

      private def tokenize_literal(ch : Char) : Tok
        if ch.ascii_letter? || ch == '_'
          tokenize_ident
        elsif ch.ascii_number?
          tokenize_number
        else
          raise ParseError.new("unexpected character '#{ch}' in expression: #{@source}")
        end
      end

      private def tokenize_bang : Tok
        advance_char
        if current_char == '='
          advance_char
          Tok.new(:Ne)
        else
          Tok.new(:Bang)
        end
      end

      private def tokenize_eq : Tok
        advance_char
        raise ParseError.new("unexpected '=' in expression: #{@source}") unless current_char == '='
        advance_char
        Tok.new(:Eq)
      end

      private def tokenize_amp : Tok
        advance_char
        raise ParseError.new("expected '&&' in expression: #{@source}") unless current_char == '&'
        advance_char
        Tok.new(:AndAnd)
      end

      private def tokenize_pipe : Tok
        advance_char
        raise ParseError.new("expected '||' in expression: #{@source}") unless current_char == '|'
        advance_char
        Tok.new(:OrOr)
      end

      private def tokenize_lt : Tok
        advance_char
        if current_char == '='
          advance_char
          Tok.new(:Le)
        else
          Tok.new(:Lt)
        end
      end

      private def tokenize_gt : Tok
        advance_char
        if current_char == '='
          advance_char
          Tok.new(:Ge)
        else
          Tok.new(:Gt)
        end
      end

      private def skip_whitespace
        while current_char == ' ' || current_char == '\t'
          advance_char
        end
      end

      private def tokenize_string : Tok
        quote = current_char
        advance_char
        text = String.build do |io|
          while current_char != quote && current_char != '\0'
            if current_char == '\\'
              advance_char
              io << current_char
              advance_char
            else
              io << current_char
              advance_char
            end
          end
        end
        raise ParseError.new("unterminated string in expression: #{@source}") if current_char != quote
        advance_char
        Tok.new(:Str, text)
      end

      private def tokenize_ident : Tok
        start = @pos
        while current_char.ascii_letter? || current_char.ascii_number? || current_char == '_'
          advance_char
        end
        text = @chars[start...@pos].join
        case text
        when "true"  then Tok.new(:TrueLit, text)
        when "false" then Tok.new(:FalseLit, text)
        when "nil"   then Tok.new(:NilLit, text)
        else              Tok.new(:Ident, text)
        end
      end

      private def tokenize_number : Tok
        start = @pos
        is_float = false
        while current_char.ascii_number?
          advance_char
        end
        if current_char == '.' && peek_char.ascii_number?
          is_float = true
          advance_char
          while current_char.ascii_number?
            advance_char
          end
        end
        text = @chars[start...@pos].join
        is_float ? Tok.new(:Float, text) : Tok.new(:Int, text)
      end
    end
  end
end

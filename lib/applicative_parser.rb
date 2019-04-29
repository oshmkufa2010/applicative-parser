require "applicative_parser/version"

module ApplicativeParser
  # Your code goes here...
 
  class Parser
    # (s -> [(a, s)]) -> Applicative a
    def initialize(&parser_func)
      @parser_func = parser_fund
    end
  
    # Parser a -> s -> [(a, s)]
    def run_parser(s)
      @parser_func.(s)
    end

    def self.lazy(&proc)
      Parser.new do |s|
        proc.call.run_parser(s)
      end
    end
  
    # Applicative a -> (a -> b) -> Applicative b
    def fmap(&f)
      Parser.new do |s|
        run_parser(s).map do |(aa, ss)|
          [f.curry.(aa), ss]
        end
      end
    end
  
    # a -> Parser a
    def self.pure(a) 
      Parser.new { |s| [[a, s]] }
    end
  
    # Parser (a -> b) -> Parser a -> Parser b
    def apply(pa) 
      Parser.new do |s|
        run_parser(s).flat_map do |f, ss|
          pa.run_parser(ss).map do |a, sss|
            [f.curry.(a), sss]
          end
        end
      end
    end
  
    # (t -> Bool) -> Parser t
    def self.satisfy(&f)
      Parser.new do |s|
        if s.length == 0
          []
        else 
          x, *xs = s
          f.(x) ? [[x, xs]] : []
        end
      end
    end
  
    def self.empty_parser
      satisfy{|_| false }
    end
  
    def self.any_token
      satisfy{|_| true }
    end
  
    def first
      Parser.new do |s|
        result = run_parser(s)
  
        if result == []     
          []
        else
         result[0..0]
        end
      end
    end
  
    # t -> Parser t
    def self.token_parser(token)
      Parser.satisfy { |t| t == token }
    end
  
    # [t] -> Parser [t]
    def self.tokens_parser(tokens)
      # parser :: Parser String
      tokens.reduce(Parser.pure([])) do |parser, token|
        Parser.pure(->(a, b) { a + [b] }).apply(parser).apply(Parser.token_parser(token))
      end
    end
  
    # Parser a -> Parser a -> Parser a
    def |(parser)
      Parser.new do |s|
        run_parser(s) + parser.run_parser(s)
      end.first
    end
  
    # Parser a -> Parser [a]
    def many
      Parser.lazy { some } | Parser.pure([])
    end 
  
    # Parser a -> Parser [a]
    def some
      fmap { |t, ts| [t] + ts }.apply(many)
    end
  
    # Parser a -> Parser b -> Parser a
    def between(left, right)
      Parser.pure(->(l, p, r) { p }).apply(left).apply(self).apply(right)
    end
  
    # Parser a -> Parser (a -> a -> a) -> Parser a 
    def chainl1(op_parser)
      rest_parser = Parser.pure(->(op, y, z) { ->(x) { z.(op.(x, y)) } }).apply(op_parser).apply(self).apply(Parser.lazy { rest_parser } ) | Parser.pure(->(x) { x })
      
      Parser.pure(->(x, rest) { rest.(x) }).apply(self).apply(rest_parser)
    end
  end
end

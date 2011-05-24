module LDAPCache
  module FilterOperation
    def op_symbol(op)
      case op
      when :eq
        '='
      when :and
          '&'
      when :or
          '|'
      when :not
          '!'
      when :present
        '=*'
      end
    end

    def unparse_filter(filter)
      filter_dup = filter.dup
      op = filter_dup.shift
      if [:true].include?(op)
        return nil
      elsif [:and, :or, :not].include?(op)
      str = "(#{op_symbol(op)}"
        filter_dup.each do |f|
          str << unparse_filter(f)
        end
      str << ")"
      else
        left = filter_dup[0]
        match_style = filter_dup[1]
        right = filter_dup[2]
        str = "(#{left}#{op_symbol(op)}#{right})"
      end
      return str
    end
  end
end

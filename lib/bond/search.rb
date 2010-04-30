module Bond
  # Contains search methods used to filter possible completions given what the user has typed for that completion.
  # For a search method to be used by Bond.complete it must end in '_search' and take two arguments: the Input
  # string and an array of possible completions.
  #
  # ==== Creating a search method
  # Say you want to create a custom search which ignores completions containing '-'.
  # In a completion file under Rc namespace, define this method:
  #   def ignore_hyphen_search(input, list)
  #     default_search(input, list.select {|e| e !~ /-/ })
  #   end
  #
  # Now you can pass this custom search to any complete() as :search=>:ignore_hyphen
  module Search
    # Searches completions from the beginning of the string.
    def default_search(input, list)
      list.grep(/^#{Regexp.escape(input)}/)
    end

    # Searches completions anywhere in the string.
    def anywhere_search(input, list)
      list.grep(/#{Regexp.escape(input)}/)
    end

    # Searches completions from the beginning and ignores case.
    def ignore_case_search(input, list)
      list.grep(/^#{Regexp.escape(input)}/i)
    end

    # Searches completions from the beginning but also provides aliasing of underscored words.
    # For example 'some_dang_long_word' can be specified as 's_d_l_w'. Aliases can be any unique string
    # at the beginning of an underscored word. For example, to choose the first completion between 'so_long' and 'so_larger',
    # type 's_lo'.
    def underscore_search(input, list)
      if input[/_(.+)$/]
        regex = input.split('_').map {|e| Regexp.escape(e) }.join("([^_]+)?_")
        list.select {|e| e =~ /^#{regex}/ }
      else
        default_search(input, list)
      end
    end

    def files_search(input, list)
      incremental_filter(input, list, '/')
    end

    def modules_search(input, list)
      incremental_filter(input, list, '::')
    end

    def incremental_filter(input, list, delim)
      i = 0; input.gsub(delim) {|e| i+= 1 }
      delim_chars = delim.split('').uniq.join('')
      current_matches, future_matches = underscore_search(input, list).partition {|e|
        e[/^[^#{delim_chars}]+(#{delim}[^#{delim_chars}]+){0,#{i}}$/] }
      (current_matches + future_matches.map {|e| e[/^(([^#{delim_chars}]+#{delim}){0,#{i+1}})/, 1] }).uniq
    end
  end
end
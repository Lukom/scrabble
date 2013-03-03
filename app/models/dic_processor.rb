class DicProcessor
  TERM_REGEX = %r(<k>(.*)</k>)
  def process
    File.open('/Users/Lukom/Downloads/ExplanatoryUkUk.dict') do |f|
      word_no = 0
      last_term = nil
      last_descr = ''
      f.each_line do |line|
        if (m = line.match(TERM_REGEX))
          last_descr << line[0...m.begin(0)]
          if last_term
            create_word(last_term, last_descr)
            word_no += 1
            puts word_no if word_no % 1000 == 0
          end
          last_term = m[1]
          last_descr = ''
        else
          last_descr << line
        end
      end
    end
  end

  def create_word(term, descr)
    accent_word = term.gsub('<nu />', '').gsub('[&apos;]', '[').gsub('[/&apos;]', ']').gsub('&apos;', '\'')
    word = accent_word.tr('[]', '')
    Word.create!(word: word, accent_word: accent_word, description: descr)
  end
end

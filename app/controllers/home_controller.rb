class HomeController < ApplicationController
  BANNED_TWO_LETTER_WORDS = %w(Ям аа ма ра юл іо)
  def two_letter_words
    @words = Word.where('LENGTH(word) = 4').all.select! { |w| !BANNED_TWO_LETTER_WORDS.include?(w.word) }
  end

  def words_with_g
    all_words = Word.where(%q(word LIKE '%ґ%')).all
    @words_by_size = all_words.group_by { |w| w.word.size }.sort.map { |len, words| [len, words.select { |w| w.word.include?('ґ') }]  }
  end

  def three_letter_words
    @words = Word.where('LENGTH(word) = 6').all
  end

  def four_letter_words
    @words = Word.where('LENGTH(word) = 8').all
  end
end

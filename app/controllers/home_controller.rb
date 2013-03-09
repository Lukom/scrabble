# -*- encoding : utf-8 -*-
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

  def riddles
    @words = Word.where(%q(LENGTH(word) = 12 AND word LIKE '%ґ%')).all
    @words.map!(&:word)
    @words.select! { |w| w.include?('ґ') }
    @words_riddles = Array.new(3).map { words_riddles(@words) }
  end

  private

  def words_riddles(words)
    words.shuffle.map { |w| word_riddle(w) }
  end

  def word_riddle(word)
    chars = word.chars.to_a
    chars += ScrabbleUtils.letters_array.sample(7 - word.size) if chars.size < 7
    chars.shuffle!
    chars.join('&nbsp;')
  end
end

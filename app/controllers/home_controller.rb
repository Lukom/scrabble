# -*- encoding : utf-8 -*-
class HomeController < ApplicationController
  BANNED_TWO_LETTER_WORDS = %w(Ям аа ма ра юл іо)
  def two_letter_words
    #@words = Word.where('CHAR_LENGTH(word) = 2').all.select! { |w| !BANNED_TWO_LETTER_WORDS.include?(w.word) }
    @words = Word.where(has_g: true).all.select { |w| w.word.count('ґ') == 3 }
  end

  def words_with_g
    all_words = Word.where(has_g: true).all
    @words_by_size = all_words.group_by { |w| w.word.size }.sort
  end

  def three_letter_words
    #@words = Word.where('CHAR_LENGTH(word) = 3').all
    @words = Word.where(%(description LIKE '%міф.%')).all
  end

  def three_letter_words_only
    @words = Word.where('CHAR_LENGTH(word) = 3').all
    @words.map! { |w|
      [w.accent_word.gsub('[', '').gsub(']', '&#769;'), w.description.scan(%r{<c>.*?</c>}).join(', '), w.description]
    }
    @words = @words.chunk { |w, dp, d| w[0] }
  end

  def four_letter_words
    @words = Word.where('CHAR_LENGTH(word) = 4').all
  end

  def riddles
    @words = Word.where('CHAR_LENGTH(word) = ?', 3).where(has_g: true).all
    @words.map!(&:word)
    @words_riddles = Array.new(3).map { words_riddles(@words) }
  end

  def g_stats
    g_words = Word.where(has_g: true).all

    @g_words_count = g_words.size
    @g_words_2_7_count = g_words.count { |w| (2..7).cover?(w.word.size) }
    @g_words_2_15_count = g_words.count { |w| (2..15).cover?(w.word.size) }

    @g_pos_stats = g_words.each_with_object({}) do |w, h|
      w.word.scan(/[ґҐ]/) do
        pos = Regexp.last_match.begin(0) + 1
        h[pos] ||= {num: 0, egs: []}
        h[pos][:num] += 1
        h[pos][:egs] << w.word
      end
    end.sort

    @g_size_stats = g_words.group_by { |w| w.word.size }.map { |size, words| [size, {num: words.size,
                                                                                     eg: words.sample.word}] }.sort

    @after_g_stats = begin
      stats = ScrabbleUtils.letter_amounts.dup.each_with_object({}) { |(letter, _), h| h[letter] = {num: 0, egs: []} }
      g_words.each do |w|
        w.word.scan(/[ґҐ](.)/) do
          char = Regexp.last_match[1]
          if stats[char]
            stats[char][:num] += 1
            stats[char][:egs] << w.word
          end
        end
      end
      stats
    end.sort_by { |_, data| data[:num] }.reverse

    @before_g_stats = begin
      stats = ScrabbleUtils.letter_amounts.dup.each_with_object({}) { |(letter, _), h| h[letter] = {num: 0, egs: []} }
      g_words.each do |w|
        w.word.scan(/(.)[ґҐ]/) do
          char = Regexp.last_match[1]
          if stats[char]
            stats[char][:num] += 1
            stats[char][:egs] << w.word
          end
        end
      end
      stats
    end.sort_by { |_, data| data[:num] }.reverse

    @letters_in_g_word_stats = begin
      letters = ScrabbleUtils.letter_amounts.keys - %w(ґ)
      stats = letters.each_with_object({}) { |letter, h| h[letter] = {num: 0, egs: []} }
      g_words.each do |w|
        letters.each do |letter|
          if w.word.include?(letter)
            stats[letter][:num] += 1
            stats[letter][:egs] << w.word
          end
        end
      end
      stats
    end.sort_by { |_, data| data[:num] }.reverse
  end

  def words_by_letters
    if params[:letters]
      @words = Word.by_letters_leq(params[:letters].chars, params[:and_one_from].to_s.chars).sort_by! { |w| w.word.size }.reverse!
    end
  end

  def sorted_by_score
    if params[:word_length]
      @words = Word.all_words(params[:word_length].to_i)
      @words.select! { |w| w.word.length >= params[:bottom_limit] } if params[:bottom_limit]
      @words.map! { |w| [w, ScrabbleUtils.word_score(w.word) || 0] }.sort_by! { |_, score| -score }
    end
  end

  def top_score_words
    #@top_score_words = Word.all_words(2..15).each_with_object([]) do |w, arr|
    #  if (score = ScrabbleUtils.word_score(w.word)) && score >= (arr.last.try(:[], 1) || 0)
    #    i = arr.rindex { |el| el[1] >= score } || -1
    #    arr.insert(i + 1, [w.word, score])
    #    arr.pop if arr.size > 20
    #  end
    #end
    @top_score_bottom_words = Word.all_words(10..15).each_with_object([]) do |w, arr|
      if (score = ScrabbleUtils.bottom_word_score(w.word)) && score >= (arr.last.try(:[], 1) || 0)
        i = arr.rindex { |el| el[1] >= score } || -1
        arr.insert(i + 1, [w.word, score])
        arr.pop if arr.size > 20
      end
    end
  end

  def sua_word_links
    Sua.new.crawle
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

class Word < ActiveRecord::Base

  class << self
    # leq = less or equal
    def by_letters_leq(letters, and_one_from = [])
      counts = letters.each_with_object({}) { |l, h| h[l] = (h[l] || 0) + 1 }
      all_words(2..8).select do |w|
        cur_counts = counts.dup
        used_one = false
        res = w.word.chars.each do |char|
          if cur_counts[char]
            cur_counts[char] -= 1
            used_one ? (break 0) : (and_one_from.include?(char) ? used_one = true : (break 0)) if cur_counts[char] < 0
          else
            used_one ? (break 0) : (and_one_from.include?(char) ? used_one = true : (break 0))
          end
        end
        res != 0
      end
    end

    def all_words(range = :all)
      @all_words ||= {}
      @all_words[range] = begin
        if range == :all
          Word.all
        elsif range.is_a?(Fixnum)
          Word.where('CHAR_LENGTH(word) = ?', range).all
        else
          Word.where('CHAR_LENGTH(word) BETWEEN ? AND ?', range.begin, range.end).all
        end
      end
    end
  end
end

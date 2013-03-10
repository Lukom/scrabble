# -*- encoding : utf-8 -*-
class ScrabbleUtils
  class << self
    def letter_amounts
      @letter_amounts ||= {
          'а' => 8,
          'б' => 2,
          'в' => 4,
          'г' => 2,
          'ґ' => 1,
          'д' => 3,
          'е' => 5,
          'є' => 1,
          'ж' => 1,
          'з' => 2,
          'и' => 7,
          'і' => 5,
          'ї' => 1,
          'й' => 1,
          'к' => 4,
          'л' => 3,
          'м' => 4,
          'н' => 7,
          'о' => 10,
          'п' => 3,
          'р' => 5,
          'с' => 4,
          'т' => 5,
          'у' => 3,
          'ф' => 1,
          'х' => 1,
          'ц' => 1,
          'ч' => 1,
          'ш' => 1,
          'щ' => 1,
          'ь' => 1,
          'ю' => 1,
          'я' => 2,
          '_' => 2,
          '\'' => 1,
      }
    end

    def letter_scores
      @letter_scores ||= {
          'а' => 1,
          'б' => 4,
          'в' => 1,
          'г' => 4,
          'ґ' => 10,
          'д' => 2,
          'е' => 1,
          'є' => 8,
          'ж' => 6,
          'з' => 4,
          'и' => 1,
          'і' => 1,
          'ї' => 6,
          'й' => 5,
          'к' => 2,
          'л' => 2,
          'м' => 2,
          'н' => 1,
          'о' => 1,
          'п' => 2,
          'р' => 1,
          'с' => 2,
          'т' => 1,
          'у' => 3,
          'ф' => 8,
          'х' => 5,
          'ц' => 6,
          'ч' => 5,
          'ш' => 6,
          'щ' => 8,
          'ь' => 5,
          'ю' => 7,
          'я' => 4,
          '_' => 0,
          '\'' => 10,
      }
    end

    def letters_array
      letter_amounts.map { |char, count| Array.new(count, char) }.sum
    end

    def word_score(word)
      empty_cells = 2
      sum = 0
      res = word.chars.each_with_object({}) do |char, h|
        h[char] = (h[char] || 0) + 1
        if !letter_amounts[char]
          break nil
        elsif h[char] <= letter_amounts[char]
          sum += letter_scores[char]
        elsif empty_cells > 0
          empty_cells -= 1
        else
          break nil
        end
      end
      res ? sum : nil
    end
  end
end

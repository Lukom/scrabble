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
          ' ' => 2,
          '\'' => 1,
      }
    end

    def letters_array
      letter_amounts.map { |char, count| Array.new(count, char) }.sum
    end
  end
end

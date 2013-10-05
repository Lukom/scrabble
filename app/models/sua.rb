# -*- encoding : utf-8 -*-
class Sua
  LETTERS_COUNT = 33
  DOMAIN_HREF = 'http://slovnyk.ua/'
  INDEX_HREF = DOMAIN_HREF + 'index.php'
  CHAPTER_HREF = INDEX_HREF + '?s1=%d&s2=0'

  def crawle
    (0...LETTERS_COUNT).each do |letter_no|
      crawle_chapter(letter_no)
    end
  end

  def crawle_chapter(letter_no)
    puts "Start crawl chapter #{letter_no}"
    chapter_links = get_words_arr(format(CHAPTER_HREF, letter_no))
    if chapter_links.first[0].start_with?('?swrd')
      save_words(chapter_links)
    else
      chapter_links.each do |link, _|
        word_links = get_words_arr(INDEX_HREF + link)
        save_words(word_links)
        wait_server
      end
    end
    wait_server
  end

  def wait_server
    sleep((1+rand).seconds)
  end

  def save_words(words_arr)
    words_arr.each do |_, word|
      w = SuaWord.new
      w.word = word
      w.save!
    end
  end

  def get_words_arr(link)
    puts("crawle #{link}")
    doc = Nokogiri::HTML(open(link))
    words_arr = doc.css('a.wordhref').map { |link| [link['href'], link.content.strip] }
    throw_parse_error(doc, 'No words found') if words_arr.empty?
    puts "Success! #{words_arr.size} word links found"
    words_arr
  end


  def crawle_all_words
    words_batch_size = 500
    while true do
      sua_words = SuaWord.select(:id, :word).where('crawled IS NULL').limit(words_batch_size)
      return 'All words are crawled' if sua_words.empty?
      sua_words.each { |sua_word| try_crawle_word(sua_word) }
    end
  end

  def try_crawle_word(sua_word)
    @crawle_wait_seconds ||= 1
    begin
      crawle_word(sua_word)
    rescue OpenURI::HTTPError => e
      @crawle_wait_seconds *= 2
      puts("OpenURI::HTTPError: #{e.message}. Wait #{@crawle_wait_seconds} seconds")
      sleep(@crawle_wait_seconds.seconds)
      crawle_word(sua_word)
    end
    @crawle_wait_seconds = 1
  end

  def crawle_word(sua_word)
    word = sua_word.word
    print("crawle word #{word}")
    doc = Nokogiri::HTML(open(INDEX_HREF + '?swrd=' + URI::escape(word.encode('windows-1251'))))
    word_header = get_nodes_ensure_count(doc, '.grayheader_left', 1).first.content.strip.presence
    if word_header != word
      sua_word.linked_word = word_header
      sua_word.linked_word_id = SuaWord.where(word: word_header).first.try(:id)
    else
      sua_word.content = doc.css('.whiteblock .bluecontent').first.try(:inner_html).try(:strip).presence
      sua_word.empty_word = true if !sua_word.content
    end
    sua_word.crawled = true
    sua_word.save!
    print(" - OK\n")
    wait_server
  end

  def get_nodes_ensure_count(doc, selector, count)
    nodeset = doc.css(selector)
    throw_parse_error(doc, selector) if nodeset.size != count
    nodeset
  end

  def throw_parse_error(doc, error_description = nil)
    puts doc.inner_html
    raise "Error! #{error_description}"
  end
end

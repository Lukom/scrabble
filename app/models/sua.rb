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

  def qwe
    puts SuaWord.where(word: 'Р').first.id
    puts SuaWord.where(word: 'РОЗКОЛ').first.id
  end

  def crawle_all_words
    words_batch_size = 100
    while true do
      #Sua.puts_complete_perc
      sua_words = SuaWord.select(:id, :word).where('crawled IS NULL AND id > 86365 AND id < 94058').order('id DESC').limit(words_batch_size)
      return 'All words are crawled' if sua_words.empty?
      sua_words.each_with_index { |sua_word, i| try_crawle_word(sua_word, i) }
    end
  end

  def try_crawle_word(sua_word, batch_i = 0)
    @crawle_wait_seconds ||= 2
    begin
      crawle_word(sua_word, batch_i)
    rescue OpenURI::HTTPError, Timeout::Error, ParseError, EOFError, Errno::ECONNRESET => e
      @crawle_wait_seconds *= 2 if @crawle_wait_seconds < 2048
      puts("#{e.class.name}: #{e.message}. Wait #{@crawle_wait_seconds} seconds")
      sleep(@crawle_wait_seconds.seconds)
      retry
    end
    @crawle_wait_seconds = 2
  end

  def crawle_word(sua_word, batch_i = 0)
    word = sua_word.word
    print(format('%s %02d crawle word %d %s - ', Time.now.strftime('%F %T'), batch_i, sua_word.id, word))
    word_url = INDEX_HREF + '?swrd=' + URI::escape(word.encode('windows-1251'))
    doc = Nokogiri::HTML(open(word_url, proxy: URI.parse('http://193.160.225.13:8081/')))
    print('O')
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
    print("K\n")
    wait_server
  end

  def get_nodes_ensure_count(doc, selector, count)
    nodeset = doc.css(selector)
    if nodeset.size != count
      if doc.title == 'ASUS Wireless Router RT-N53 - Error message'
        raise ParseError.new('My Router Error')
      elsif doc.css('b').any? { |node| node.inner_html == 'DB query error.' }
        raise ParseError.new('DB Query Error')
      else
        throw_parse_error(doc, selector)
      end
    end
    nodeset
  end

  def throw_parse_error(doc, error_description = nil)
    puts doc.inner_html
    raise "Error! #{error_description}"
  end

  def self.puts_complete_perc
    puts "Completed: #{(SuaWord.where(crawled: true).count/SuaWord.count.to_f*1000).floor/10.0}%"
  end

  def crawle_all_with_selenium
    @driver = Selenium::WebDriver.for :firefox
    @wait = Selenium::WebDriver::Wait.new(timeout: 20)
    words_batch_size = 100
    while true do
      Sua.puts_complete_perc
      sua_words = SuaWord.select(:id, :word).where('crawled IS NULL').limit(words_batch_size)
      (puts 'All words are crawled'; return) if sua_words.empty?
      sua_words.each_with_index do |sua_word, i|
        word = sua_word.word
        print(format('%s %02d crawle word %d %s - ', Time.now.strftime('%F %T'), i, sua_word.id, word))
        word_url = INDEX_HREF + '?swrd=' + URI::escape(word.encode('windows-1251'))
        @driver.navigate.to word_url

        if @wait.until { @driver.find_elements(:css, 'b') }.any? { |el| el.text == 'DB query error.' }
          raise ParseError.new('DB Error')
        end
        word_header = @wait.until { @driver.find_elements(:css, '.grayheader_left') }.first.text.strip
        if word_header != word
          sua_word.linked_word = word_header
          sua_word.linked_word_id = SuaWord.where(word: word_header).first.try(:id)
        else
          sua_word.content = @wait.until { @driver.find_elements(:css, '.whiteblock .bluecontent') }.first.attribute('innerHTML').strip.presence
          sua_word.empty_word = true if !sua_word.content
        end
        sua_word.crawled = true
        sua_word.save!
        print("OK\n")
      end
    end
  #ensure
  #  @driver.quit
  end

  def crawle_arr
    arr = SuaWord.select(:id).where(crawled: nil).map(&:id).shuffle
    puts arr
    i = 0
    while true
      i = i % arr.size
      id = arr[i]
      begin
        Sua.new.crawle_word(SuaWord.find(id), 0)
        arr.delete_at(i)
      rescue StandardError => e
        puts e.class.name
      end
      i += 1
    end
  end
end

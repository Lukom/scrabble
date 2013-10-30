# -*- encoding : utf-8 -*-
class Ulif
  DICT_HREF = 'http://lcorp.ulif.org.ua/dictua/dictua.aspx'
  FIRST_WORD = 'а'
  LAST_WORD = 'Я́я'
  LINKS_COUNT = 25

  def try_crawle_all
    @crawle_wait_seconds = 60
    begin
      crawle_all
    rescue Selenium::WebDriver::Error::StaleElementReferenceError => e
      puts "\n#{e.class.name}: #{e.message}. Wait #{@crawle_wait_seconds} seconds"
      sleep(@crawle_wait_seconds.seconds)
      retry
    end
  end

  def crawle_all
    last_crawled_word = UlifWord.where('crawled IS NOT NULL').order('id DESC').first
    if !last_crawled_word
      @initial_word = FIRST_WORD
      @initial_ignore = 0
    else
      @initial_word = last_crawled_word.word
      @initial_ignore =  UlifWord.where(word: @initial_word).count
    end
    @driver = Selenium::WebDriver.for :firefox
    @wait = Selenium::WebDriver::Wait.new(timeout: 10)
    begin
      @driver.navigate.to DICT_HREF
      wait_server
      @wait.until { @driver.find_element(:id, 'ctl00_ContentPlaceHolder1_tsearch') }.send_keys @initial_word
      @wait.until { @driver.find_element(:id, 'ctl00_ContentPlaceHolder1_search') }.click
      @initial_batch = true
      catch :the_end do
        while true
          crawle_batch_words
          @wait.until { @driver.find_element(:id, 'ctl00_ContentPlaceHolder1_nextpage') }.click
        end
        puts 'All words crawled!'
      end
    ensure
      @driver.quit
    end
  end

  def crawle_batch_words
    puts 'crawle batch'
    wait_server(2)
    if @initial_batch
      words = @wait.until { @driver.find_elements(:css, '#ctl00_ContentPlaceHolder1_WordList a') }.map(&:text)
      @link_no = words.index(@initial_word) + @initial_ignore
      puts "Skip: #{words[0...@link_no].join(', ')}" if @link_no > 0
      @initial_batch = false
    else
      @link_no = 0
    end

    while @link_no < LINKS_COUNT
      print "#{@link_no} "
      links = @wait.until { @driver.find_elements(:css, '#ctl00_ContentPlaceHolder1_WordList a') }
      link = links[@link_no]
      word = link.text
      print "#{word} - "
      link.click
      wait_server
      save_word(word)
      print "OK\n"
      throw :the_end if word == LAST_WORD
      @link_no += 1
    end
  end

  def save_word(word)
    @last_word ||= ''
    @word_no ||= 0
    w = UlifWord.new(word: word)
    word == @last_word ? @word_no += 1 : @word_no = 1
    w.no = @word_no
    @last_word = word
    w.content = @wait.until { @driver.find_element(:id, 'article_full').attribute('innerHTML') }
    w.has_syn = @driver.find_elements(:id, 'ctl00_ContentPlaceHolder1_syn').any?
    w.has_phras = @driver.find_elements(:id, 'ctl00_ContentPlaceHolder1_phras').any?
    w.crawled = true
    w.save!
  end

  def wait_server(secs = 1.5)
    sleep((secs+rand).seconds)
  end
end

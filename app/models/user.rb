require 'net/http'
require 'uri'
require 'rexml/document' 
require 'rexml/xpath'
require 'RMagick'
require 'timeout'

class User < ActiveRecord::Base
  background :update_accounts, :every => 1.minute, :concurrent => false	  
  has_many :friends
  
  # get a user id based on email
  def self.get_user_id (email)		
    # get the userid of the user creating a map		
    resp = self.get_page('http://search.myspace.com/index.cfm?fuseaction=find.search&searchType=network&interesttype=&country=&searchBy=Email&f_first_name='+email+'&Submit=Find')    
    profileRE = /friendID=(.*?)">/	
    user_id = profileRE.match(resp.to_s)[1]		
    user_id.to_s    
  rescue
    logger.info("WMFL ERROR Error in get_user_id")   
    nil
  end
  
  # get username based on id
  def self.get_info(user_id)
    info = Array.new                         
    resp = get_page('http://profile.myspace.com/index.cfm?fuseaction=user.viewprofile&friendid='+user_id)    
    
    locationRE = /content="MySpace Profile -(.*?),.*?,.*?,(.*?),(.*?),(.*?),.*?\/>/
    matches = locationRE.match(resp)
    if(matches)
      username = matches[1]
      info << username
      
      musicRE = /id="ProfileMusic".*?>(.*?)<\/td><\/tr>/ms
      musicMatches = musicRE.match(resp)
      if(musicMatches)
        info << musicMatches[1]
      else
        info << ""
      end
      
      moviesRE = /id="ProfileMovies".*?>(.*?)<\/td><\/tr>/ms
      movieMatches = moviesRE.match(resp)
      if(movieMatches)
        info << movieMatches[1]
      else
        info << ""
      end
      
      booksRE = /id="ProfileBooks".*?>(.*?)<\/td><\/tr>/ms
      bookMatches = booksRE.match(resp)
      if(bookMatches)
        info << bookMatches[1]
      else
        info << ""
      end
      
      info          
    else
      nil
    end
  rescue 
    logger.info("WMFL ERROR Error in get_info")   
    nil
  end
  
  
  def self.get_num_friends(user_id) 
    @recordsRE = /Listing[\s\t\r\n\f]*.*?[\s\t\r\n\f]*of[\s\t\r\n\f]*(.*?)[\s\t\r\n\f]*<\/div>/
    url = 'http://home.myspace.com/index.cfm?fuseaction=user.viewfriends&friendID='+user_id
    resp = self.get_page(url)
    num_r = @recordsRE.match(resp.to_s)[1]   	
    num_records = num_r.to_i
  rescue 
    logger.info("WMFL ERROR Error in get_num_friends")   
    nil    
  end
  
  def self.get_friends(user_id, num_records)
    friends = Array.new	    
    count = 1
    previous_record_last = ""
    previous_record_first = ""
    while count <= num_records/40 + 1
      url = 'http://home.myspace.com/index.cfm?fuseaction=user.viewfriends&friendID='+user_id+'&friendCount='+num_records.to_s+'&page='+count.to_s+'&PREVPageLASTONERETURENED='+previous_record_last+'&prevPage='+(count-1).to_s+'&PREVPageFirstONERETURENED='+previous_record_first
      resp = self.get_page(url)	            
      @recordsRE = /CLASS="DataPoint=OnlineNow;UserID=(.*?);/
      array_count = 0
      resp.scan(@recordsRE).each { |entry|
        if(array_count == 0)
          previous_record_first = entry.to_s
        end
        friends << entry.to_s
        previous_record_last = entry.to_s
        array_count+=1
      }      
      count+=1
    end 
    if(friends && friends.size > 0)
      friends
    else
      nil
    end
  rescue  
    logger.info("WMFL ERROR Error in get_friends")   
    nil
  end
  
  def self.update_accounts
    users = self.find(:all, 
                    :conditions => ["active = 0 or updated_at < ?", 7.days.ago])
    for user in users
      # get the user id associated with the email address provided
      user_id = user.myspace_id
      
      # get the username for the user id
      info = self.get_info(user_id)
      if(info)      
        user.username = info[0]      
        num_friends = self.get_num_friends(user_id)      
        friends = self.get_friends(user_id, num_friends)
        if(friends)
          user.save      
          
          for friend_id in friends
            friend_info = self.get_info(friend_id)                        
            if(friend_info)          
              friend = Friend.new
              friend.user_id = user.id
              friend.myspace_id = friend_id
              friend.username = friend_info[0]
              
              # clean up the music list and tokenize it
              music_list = self.get_clean_list(friend_info[1])
              
              # clean up the movie list and tokenize it
              movie_list = self.get_clean_list(friend_info[2])
              
              # clean up the book list and tokenize it
              book_list = self.get_clean_list(friend_info[3])
              
              # add the music to the friend
              for music in music_list
                if(music)
                  new_music = Music.new
                  new_music.name = music
                  new_music.myspace_id = friend.myspace_id
                  friend.musics << new_music
                end
              end
              
              # add the movies to the friend
              for movie in movie_list
                if(movie)
                  new_movie = Movie.new
                  new_movie.name = movie
                  new_movie.myspace_id = friend.myspace_id               
                  friend.movies << new_movie              
                end
              end
              
              # add the books to the friend
              for book in book_list
                if(book)
                  new_book = Book.new
                  new_book.name = book
                  new_book.myspace_id = friend.myspace_id               
                  friend.books << new_book
                end
              end
              
              # add the friend to the user
              user.friends << friend
            end                       
            
          end
          user.active = 1
          if(user.update)
            CreationNotifier.deliver_creation_notification(user.email)
          end      
          self.create_image(user.id.to_s, user.image_location)      
        end
      end
    end
  rescue Exception => exception
    SystemNotifier.deliver_exception_notification(exception)    
    logger.info("Error in update_accounts: " + exception)
  end
  
  def self.clean_name(name)
    if(name)
      name = name.strip          
      name = name.gsub(/^a /, "").gsub(/^the /, "")
      name = name.gsub(/^& /, "")
      if(name.length <= 2)
        nil
      else
        name
      end
    else
      nil
    end
  end
  
  def self.clean_list(list)
    if(list)
      list = list.gsub(/<[^>]*>/, "") 	
      list = list.gsub(/[\t\r\n\f]/, " ") 	
      list = list.gsub("-", ",").gsub(":", ",").gsub("*", ",")
      list = list.gsub(";", ",").gsub(".", ",").gsub("\"", "")
      list = list.gsub("/", ",")
      list.downcase.strip
    else
      nil
    end
  end
  
  def self.get_clean_list(info)
    new_list = Array.new
    long_string = self.clean_list(info)
    if(long_string)
      string_list = long_string.split(",")
      for text in string_list
        cleaned_text = self.clean_name(text)
        if(cleaned_text)
          new_list << cleaned_text
        end
      end           
    end
    new_list.uniq  
  end  
  
  def self.create_image(userid, filename)  
    
    music = Music.find_by_sql(["select  "+
        "distinct(musics.name) as music_name, "+
        "count(musics.name) as music_count, "+
        "friends.username "+
        "from "+
        "musics, "+ 
        "friends, "+
        "users "+
        "where "+
        "users.id = ? and "+
        "friends.user_id = users.id and "+
        "musics.friend_id = friends.id "+
        "GROUP BY music_name "+
        "order by music_count DESC "+
        "limit 1", userid])
    if(music && music.size > 0)
      music_name = music[0].music_name
    else
      music_name = ""
    end
    
    movie = Movie.find_by_sql(["select  "+
        "distinct(movies.name) as movie_name, "+
        "count(movies.name) as movie_count "+
        "from "+
        "movies, "+ 
        "friends, "+
        "users "+
        "where "+
        "users.id = ? and "+
        "friends.user_id = users.id and "+
        "movies.friend_id = friends.id "+
        "GROUP BY movie_name "+
        "order by movie_count DESC "+
        "limit 1", userid])    
    if(movie && movie.size > 0)
      movie_name = movie[0].movie_name
    else
      movie_name = ""
    end
    
    book = Book.find_by_sql(["select  "+
        "distinct(books.name) as book_name, "+
        "count(books.name) as book_count "+
        "from "+
        "books, "+ 
        "friends, "+
        "users "+
        "where "+
        "users.id = ? and "+
        "friends.user_id = users.id and "+
        "books.friend_id = friends.id "+
        "GROUP BY book_name "+
        "order by book_count DESC "+
        "limit 1", userid])       
    if(book && book.size > 0)
      book_name = book[0].book_name
    else
      book_name = ""
    end
    
    fullpath = "/home/whatmy/www/"    
    
    granite = Magick::ImageList.new('granite:')
    canvas = Magick::ImageList.new
    canvas.new_image(300, 100, Magick::TextureFill.new(granite))
    
    text = Magick::Draw.new
    text.font_family = 'helvetica'
    text.pointsize = 16
    
    text.annotate(canvas, 0,0,70,14, "WhatMyFriendsLike.com") {
      self.fill = 'darkred'
    }    
    text.annotate(canvas, 0,0,10,34, "Top Music: " + music_name) {
      self.fill = 'darkred'
    }    
    text.annotate(canvas, 0,0,10,62, "Top Movie: " + movie_name) {
      self.fill = 'darkred'
    }    
    text.annotate(canvas, 0,0,10,89, "Top Book: " + book_name) {
      self.fill = 'darkred'
    }        
    canvas.write(fullpath+filename)
    filename
  end
  
  protected
  
  # retrieve a page
  def self.get_page(url)
    resp = nil
    begin
      timeout(600) do
        resp = Net::HTTP.get(URI.parse(url))	
        resp.to_s    
      end
    rescue TimeoutError
      logger.info("WMFL ERROR url: " + url)
      logger.info("WMFL ERROR Timeout error in get_page")
      retry
    end
    resp.to_s    
  rescue 
    logger.info("WMFL ERROR Unknown error in get_page")
    nil
  end
  
  def before_save
    Friend.delete_all(["user_id = ?", self.id])
  end
  
end

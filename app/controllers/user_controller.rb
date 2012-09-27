class UserController < ApplicationController
  
  def page_not_found
  end
  
  def error_page
  end
  
  def index
    @user = User.find_by_email("davidnaffis@yahoo.com")
    @user_id = @user.id
    @musics = Music.find_by_sql(["select  "+
        "distinct musics.name as item_name, "+
        "count(musics.name) as item_count "+
        "from "+
        "musics, "+ 
        "friends, "+
        "users "+
        "where "+
        "users.id = ? and "+
        "friends.user_id = users.id and "+
        "musics.friend_id = friends.id "+
        "GROUP BY item_name "+
        "order by item_count DESC "+
        "limit 5", @user_id])         
  end
  
  def who_movies
    name = params['name']   
    @user_id = params['user_id']   
    @item_name = name
    
    @friends = Friend.find_by_sql(["select " +
      "friends.id, " +
      "friends.myspace_id, " +
      "friends.username " +            
      "from " +
      "friends, " +
      "movies " +   
      "where " +
      "friends.user_id = ? AND " +   
      "friends.id = movies.friend_id AND " +   
      "movies.name = ?", @user_id, name])                      
  end
  
  def who_music
    name = params['name']   
    @user_id = params['user_id']   
    @item_name = name
    
    @friends = Friend.find_by_sql(["select " +
      "friends.id, " +
      "friends.myspace_id, " +
      "friends.username " +            
      "from " +
      "friends, " +
      "musics " +   
      "where " +
      "friends.user_id = ? AND " +   
      "friends.id = musics.friend_id AND " +   
      "musics.name = ?", @user_id, name])  
  end
  
  def who_books
    name = params['name']   
    @user_id = params['user_id']       
    @item_name = name
    
    @friends = Friend.find_by_sql(["select " +
      "friends.id, " +
      "friends.myspace_id, " +
      "friends.username " +            
      "from " +
      "friends, " +
      "books " +   
      "where " +
      "friends.user_id = ? AND " +   
      "friends.id = books.friend_id AND " +   
      "books.name = ?", @user_id, name])  
  end
  
  def also_like
    id = params['id']
    @user_id = params['user_id']
    @movies = Movie.find_all(["friend_id = ?", id])
    @musics = Music.find_all(["friend_id = ?", id])
    @books = Book.find_all(["friend_id = ?", id]) 
    friend = Friend.find(id)       
    @username = friend.username
    @myspace_id = friend.myspace_id
  end


  def find_code
  end

  def code
    @statuses = Array.new
    email = params['user']['email']
    user = User.find_by_email(email)    
    if(user)     
      @statuses << "Found account information for " + email
      @saved_user_id = user.id.to_s
      @image_location = user.image_location
    else
      @statuses << "Unable to find account information for " + email
    end        
  end
      
  def new    
  end

  def create
    @statuses = Array.new
    
    email = params['user']['email'] 
    user = User.find_by_email(email)
    if(user)
      @statuses <<  "If you need your html code or account page please click 'Get Your Code' above."
      @statuses << "Your account is automatically updated every week. "
      @statuses << "Your account was updated on " + user.updated_at.to_s
    else                      
      # get the user id associated with the email address provided
      user_id = get_user_id(email)	
      if(!user_id)
        @statuses << "Unable to get user information. Please try again or report this problem."
        raise "WMFL ERROR get_user_id error"
      end
      
      # get the username for the user id
      info = get_user_info(user_id)        
      if(!info)
        @statuses << "Unable to get user information. Please try again or report this problem."      
        raise "WMFL ERROR get_user_info error"
      end
      
      user = User.new
      user.email = email
      user.myspace_id = user_id
      user.username = info[0]
      user.image_location = "assets/#{Time.now.utc.to_i}#{rand(10000000000)}.gif"
      user.active = 0      
      
      if(user.save)     
        @statuses << "You'll receive an email when your account is created."      
        @statuses << "Your account should be created within 10 minutes."      
        @statuses << "Saving information for " + email
        @saved_user_id = user.id.to_s
        @image_location = user.image_location
      else
        @statuses << "Unable to save user information. Please try again or report this problem."
      end            
    end
  rescue
    @statuses << "There was an error. Unable to continue."
  end
  
  def items
    @user_id = params[:id]
    @user = User.find(@user_id)
    @musics = Music.find_by_sql(["select  "+
        "distinct musics.name as item_name, "+
        "count(musics.name) as item_count "+
        "from "+
        "musics, "+ 
        "friends, "+
        "users "+
        "where "+
        "users.id = ? and "+
        "friends.user_id = users.id and "+
        "musics.friend_id = friends.id "+
        "GROUP BY item_name "+
        "order by item_count DESC "+
        "limit 5", @user_id])
    
    @movies = Movie.find_by_sql(["select  "+
        "distinct movies.name as item_name, "+
        "count(movies.name) as item_count "+
        "from "+
        "movies, "+ 
        "friends, "+
        "users "+
        "where "+
        "users.id = ? and "+
        "friends.user_id = users.id and "+
        "movies.friend_id = friends.id "+
        "GROUP BY item_name "+
        "order by item_count DESC "+
        "limit 5", @user_id])    
    
    @books = Book.find_by_sql(["select  "+
        "distinct books.name as item_name, "+
        "count(books.name) as item_count "+
        "from "+
        "books, "+ 
        "friends, "+
        "users "+
        "where "+
        "users.id = ? and "+
        "friends.user_id = users.id and "+
        "books.friend_id = friends.id "+
        "GROUP BY item_name "+
        "order by item_count DESC "+
        "limit 5", @user_id])         
  end
  
  ###########################################################################
  protected  
  
  def get_num_friends(user_id)
    num_records = User.get_num_friends(user_id)        
    num_records
  end
  
  def get_user_id(email)
    user_id = User.get_user_id(email)	
    if(user_id)
      user_id
    else      
      nil
    end    
  end
  
  def get_user_info(user_id)
    info = User.get_info(user_id)    
    if(info)
      info
    else
      nil
    end      
  end
  
  def get_friend_info(user_id)
    info = User.get_info(user_id)    
    if(info)
      info
    else
      nil
    end      
  end
  
  def get_friends(user_id, num_records)
    friends = User.get_friends(user_id, num_records)
    if(friends)
      friends
    else
      nil
    end
  end   
  
end

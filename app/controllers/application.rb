# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  before_filter :get_main_ranks

  def rescue_action(exception)
    case exception
      when ::ActiveRecord::RecordNotFound, ::ActionController::UnknownAction
        render(:controller => 'user', :action => 'page_not_found')
      else        
        SystemNotifier.deliver_exception_notification(exception)
    end
  end
  
  def rescue_action_in_public(exception)
    case exception
      when ::ActiveRecord::RecordNotFound, ::ActionController::UnknownAction
        render(:controller => 'user', :action => 'page_not_found')
      else
        SystemNotifier.deliver_exception_notification(exception)
    end
  end
  
  def get_main_ranks
    @musics_main = Music.find_by_sql("select " +
      "musics.name as item_name, " +
      "count(distinct musics.myspace_id) as item_count " +
      "from " +
      "musics " +
      "GROUP BY item_name " +
      "order by item_count DESC " +
      "limit 5 ")   

    @movies_main = Movie.find_by_sql("select " +
      "movies.name as item_name, " +
      "count(distinct movies.myspace_id) as item_count " +
      "from " +
      "movies " +
      "GROUP BY item_name " +
      "order by item_count DESC " +
      "limit 5 ")   

    @books_main = Book.find_by_sql("select " +
      "books.name as item_name, " +
      "count(distinct books.myspace_id) as item_count " +
      "from " +
      "books " +
      "GROUP BY item_name " +
      "order by item_count DESC " +
      "limit 5 ")                  
  end
  
end
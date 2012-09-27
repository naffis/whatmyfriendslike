class CreationNotifier < ActionMailer::Base
  SYSTEM_EMAIL_ADDRESS = %{"WhatMyFriendsLike" <admin@whatmyfriendslike.com>}

  def creation_notification(email)
    @subject = "Your WhatMyFriendsLike.com account"
    @body = {}
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = email
    @headers = {}
  end 
    
end

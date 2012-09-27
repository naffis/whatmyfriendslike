class Friend < ActiveRecord::Base
	belongs_to :user
	has_many :books
	has_many :musics
	has_many :movies    
    
end

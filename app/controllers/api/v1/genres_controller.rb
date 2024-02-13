module Api
  module V1
    class GenresController < ApplicationController
      def random_song
        genre_name = params[:genre_name]
        songs = Song.where(genre: genre_name).sample
        render json: { data: songs }
      end
    end
  end
end

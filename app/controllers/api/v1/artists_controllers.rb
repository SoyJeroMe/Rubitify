# app/controllers/api/v1/artists_controller.rb
module Api
  module V1
    class ArtistsController < ApplicationController
      def index
        artists = Artist.order(popularity: :desc)
        render json: { data: artists }
      end
    end
  end
end

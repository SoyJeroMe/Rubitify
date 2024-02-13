# lib/tasks/spotify_import.rake

require 'httparty'

namespace :spotify do
  desc "Import data from Spotify"
  task :import => :environment do
    client_id = ENV['73cd7f5dee4048cb84c874fd17d5c84b']
    client_secret = ENV['0051cda4b9854d2d89c25ce3f1cc7b3e']
    access_token = get_access_token(client_id, client_secret)

    if access_token.present?
      import_artists(access_token)
      import_albums(access_token)
      import_songs(access_token)
    else
      puts "Error: Failed to obtain access token"
    end
  end

  def get_access_token(client_id, client_secret)
    response = HTTParty.post("https://accounts.spotify.com/api/token", body: {
      grant_type: 'client_credentials'
    }, basic_auth: {
      username: client_id,
      password: client_secret
    })

    if response.success?
      data = JSON.parse(response.body)
      return data['access_token']
    else
      return nil
    end
  end

  def import_artists(access_token)
    response = HTTParty.get("https://api.spotify.com/v1/search?q=artist&type=artist", headers: {
      "Authorization" => "Bearer #{access_token}"
    })

    if response.success?
      data = JSON.parse(response.body)

      data["artists"]["items"].each do |artist_data|
        artist = Artist.find_or_initialize_by(spotify_id: artist_data["id"])
        artist.name = artist_data["name"]
        artist.image = artist_data["images"].first["url"] if artist_data["images"].present?
        artist.genres = artist_data["genres"]
        artist.popularity = artist_data["popularity"]
        artist.spotify_url = artist_data["external_urls"]["spotify"]
        artist.save
      end

      puts "Imported #{data["artists"]["items"].size} artists"
    else
      puts "Error importando artistas: #{response.code}, #{response.message}"
    end
  end

  def import_albums(access_token)
    Artist.find_each do |artist|
      response = HTTParty.get("https://api.spotify.com/v1/artists/#{artist.spotify_id}/albums", headers: {
        "Authorization" => "Bearer #{access_token}"
      })

      if response.success?
        data = JSON.parse(response.body)

        data["items"].each do |album_data|
          album = Album.find_or_initialize_by(spotify_id: album_data["id"])
          album.name = album_data["name"]
          album.image = album_data["images"].first["url"] if album_data["images"].present?
          album.spotify_url = album_data["external_urls"]["spotify"]
          album.total_tracks = album_data["total_tracks"]
          album.save
        end

        puts "Imported #{data["items"].size} albums for artist #{artist.name}"
      else
        puts "Error importing albums for artist #{artist.name}: #{response.code}, #{response.message}"
      end
    end
  end

  def import_songs(access_token)
    Album.find_each do |album|
      response = HTTParty.get("https://api.spotify.com/v1/albums/#{album.spotify_id}/tracks", headers: {
        "Authorization" => "Bearer #{access_token}"
      })

      if response.success?
        data = JSON.parse(response.body)

        data["items"].each do |song_data|
          song = Song.find_or_initialize_by(spotify_id: song_data["id"])
          song.name = song_data["name"]
          song.spotify_url = song_data["external_urls"]["spotify"]
          song.preview_url = song_data["preview_url"]
          song.duration_ms = song_data["duration_ms"]
          song.explicit = song_data["explicit"]
          song.save
        end

        puts "importando #{data["items"].size} cancion del album #{album.name}"
      else
        puts "Error importando cancion del album #{album.name}: #{response.code}, #{response.message}"
      end
    end
  end
end

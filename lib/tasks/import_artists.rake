namespace :import do
  desc "Import artists from artists.yml"
  task :artists => :environment do
    artists = YAML.load_file("#{Rails.root}/lib/tasks/artists.yml")

    artists["artists"].each do |artist_data|
      artist_name = artist_data["name"]
      artist = Artist.find_or_create_by(name: artist_name)

      # Importar álbumes del artista desde la API de Spotify
      response = HTTParty.get("https://api.spotify.com/v1/search?q=#{CGI.escape(artist_name)}&type=artist", headers: {
        "Authorization" => "Bearer #{get_access_token}"
      })

      if response.success?
        data = JSON.parse(response.body)
        artist_spotify_id = data["artists"]["items"].first["id"]

        albums_response = HTTParty.get("https://api.spotify.com/v1/artists/#{artist_spotify_id}/albums", headers: {
          "Authorization" => "Bearer #{get_access_token}"
        })

        if albums_response.success?
          albums_data = JSON.parse(albums_response.body)["items"]
          albums_data.each do |album_data|
            album_name = album_data["name"]
            album = artist.albums.find_or_create_by(name: album_name)

            # Importar canciones del álbum desde la API de Spotify
            songs_response = HTTParty.get("https://api.spotify.com/v1/albums/#{album_data["id"]}/tracks", headers: {
              "Authorization" => "Bearer #{get_access_token}"
            })

            if songs_response.success?
              songs_data = JSON.parse(songs_response.body)["items"]
              songs_data.each do |song_data|
                song_name = song_data["name"]
                song = album.songs.find_or_create_by(name: song_name)
                # Importar otros detalles de la canción según sea necesario
              end
            else
              puts "Error importing songs for album #{album_name}: #{songs_response.code}, #{songs_response.message}"
            end
          end
        else
          puts "Error importing albums for artist #{artist_name}: #{albums_response.code}, #{albums_response.message}"
        end
      else
        puts "Error searching for artist #{artist_name}: #{response.code}, #{response.message}"
      end

      puts "Imported artist: #{artist.name}"
    end
  end

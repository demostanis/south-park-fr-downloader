require 'uri'
require 'net/http'

uri = URI'https://www.south-park-tv.biz/'
res = Net::HTTP.get uri
res
  .scan(/<a class="ubermenu-target[^"]+" href="([^"]+)"><span class="ubermenu-target-title[^"]+">([^<]+)<\/span><\/a>/)
  .each do |url, name|
    if name =~ /(?:Saison \d+ )?Episode (\d+)/ then
      if $episode.nil? || $1.to_i < $episode
        $season ||= 0
        $season += 1
      end
      $episode = $1.to_i

      episode = sprintf "%.2d", $1
      link = URI"https://www.south-park-tv.biz/storage7869876976/southpark#{$season}x#{episode}.mp4"

      Net::HTTP.start(link.host, link.port, :use_ssl => true) do |client|
        total = client.head(link, { 'Referer' => url })['Content-Length'].to_i
        print "Downloading season \033[1m#{$season}\033[0m, episode \033[1m#{$episode}\033[0m:     "
        counter = 0

        dir = "Saison #{$season}"
        Dir.mkdir(dir) if not Dir.exists? dir
        file = "#{dir}/Episode #{episode}.mp4"

        File.open(file, 'w') do |f|
          client.get(link, { 'Referer' => url }) do |buf|
            f.write(buf)
            counter += buf.length
            backspaces = "\b" * (($percentage || 100).to_s.length + 1)
            $percentage = (counter.to_f / total.to_f * 100).to_i
            print "#{backspaces}\033[32;1m#{$percentage}%\033[0m"
          end
        end

        puts "\b\b\b\bdone"
      end
    end
  end

